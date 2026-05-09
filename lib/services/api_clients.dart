import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../models/models.dart';
import 'local_store.dart';

class SupabaseRestClient {
  SupabaseRestClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse(
            '${AppConfig.supabaseUrl.replaceAll(RegExp(r"/$"), "")}$path')
        .replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'apikey': AppConfig.supabaseApiKey,
        if (AppConfig.supabaseApiKey.startsWith('eyJ'))
          'Authorization': 'Bearer ${AppConfig.supabaseApiKey}',
        'Content-Type': 'application/json',
      };

  void _ensureConfigured() {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase is not configured. Use --dart-define keys.');
    }
  }

  Future<UserProfile> register(String name, String phoneNumber) async {
    _ensureConfigured();
    final existing = await _findUserByPhone(phoneNumber);
    if (existing != null) throw StateError('Phone number already registered.');

    final response = await _client.post(
      _uri('/rest/v1/users', {'select': '*'}),
      headers: {..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode({'name': name, 'phone_number': phoneNumber}),
    );
    return _single(response, UserProfile.fromJson);
  }

  Future<UserProfile> login(String phoneNumber) async {
    _ensureConfigured();
    final user = await findUserByPhone(phoneNumber);
    if (user == null) {
      throw StateError('No account found for this phone number.');
    }
    return user;
  }

  Future<UserProfile?> findUserByPhone(String phoneNumber) async {
    _ensureConfigured();
    return _findUserByPhone(phoneNumber);
  }

  Future<UserProfile> updateUserProfile({
    required int userId,
    required String name,
    required String phoneNumber,
  }) async {
    _ensureConfigured();
    final response = await _client.patch(
      _uri('/rest/v1/users', {'id': 'eq.$userId', 'select': '*'}),
      headers: {..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode({
        'name': name,
        'phone_number': phoneNumber,
      }),
    );
    return _single(response, UserProfile.fromJson);
  }

  Future<void> deleteAccount({
    required UserProfile user,
    required String reason,
  }) async {
    _ensureConfigured();
    try {
      await _client.post(
        _uri('/rest/v1/account_deletion_feedback'),
        headers: _headers,
        body: jsonEncode({
          'user_id': user.id,
          'name': user.name,
          'phone_number': user.phoneNumber,
          'reason': reason,
        }),
      );
    } catch (_) {
      // Deletion should still proceed if the feedback table is not deployed yet.
    }

    final response = await _client.delete(
      _uri('/rest/v1/users', {'id': 'eq.${user.id}'}),
      headers: _headers,
    );
    _check(response);
  }

  Future<List<Farmland>> getFarmlands(int userId) async {
    _ensureConfigured();
    final response = await _client.get(
      _uri('/rest/v1/farmlands', {
        'user_id': 'eq.$userId',
        'select': '*',
        'order': 'name.asc',
      }),
      headers: _headers,
    );
    return _list(response, Farmland.fromJson);
  }

  Future<Farmland> createFarmland(Farmland farmland) async {
    _ensureConfigured();
    final response = await _client.post(
      _uri('/rest/v1/farmlands', {'select': '*'}),
      headers: {..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode(farmland.toJson()),
    );
    return _single(response, Farmland.fromJson);
  }

  Future<Farmland> updateFarmland(Farmland farmland) async {
    _ensureConfigured();
    final response = await _client.patch(
      _uri('/rest/v1/farmlands', {'id': 'eq.${farmland.id}', 'select': '*'}),
      headers: {..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode(farmland.toJson()..remove('user_id')),
    );
    return _single(response, Farmland.fromJson);
  }

  Future<void> deleteFarmland(String farmlandId) async {
    _ensureConfigured();
    final response = await _client.delete(
      _uri('/rest/v1/farmlands', {'id': 'eq.$farmlandId'}),
      headers: _headers,
    );
    _check(response);
  }

  Future<List<PestAlert>> getAlerts() async {
    _ensureConfigured();
    final response = await _client.get(
      _uri('/rest/v1/pest_alerts', {'select': '*', 'order': 'timestamp.desc'}),
      headers: _headers,
    );
    return _list(response, PestAlert.fromJson);
  }

  Future<List<MarketplaceListing>> getMarketplaceListings({
    String? listingType,
    int limit = 50,
  }) async {
    _ensureConfigured();
    final query = <String, String>{
      'select': '*,users(name)',
      'status': 'eq.active',
      'order': 'created_at.desc',
      'limit': '$limit',
    };
    if (listingType != null && listingType.trim().isNotEmpty) {
      query['listing_type'] = 'eq.${listingType.trim()}';
    }
    final response = await _client.get(
      _uri('/rest/v1/marketplace_listings', query),
      headers: _headers,
    );
    return _list(response, MarketplaceListing.fromJson);
  }

  Future<MarketplaceListing> createMarketplaceListing({
    required int userId,
    required String listingType,
    required String title,
    String? description,
    String? cropType,
    String? quantity,
    double? price,
  }) async {
    _ensureConfigured();
    final response = await _client.post(
      _uri('/rest/v1/marketplace_listings', {'select': '*,users(name)'}),
      headers: {..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode({
        'user_id': userId,
        'listing_type': listingType,
        'title': title,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (cropType != null && cropType.trim().isNotEmpty)
          'crop_type': cropType.trim(),
        if (quantity != null && quantity.trim().isNotEmpty)
          'quantity': quantity.trim(),
        if (price != null && price > 0) 'price': price,
        'status': 'active',
      }),
    );
    return _single(response, MarketplaceListing.fromJson);
  }

  Future<UserProfile?> _findUserByPhone(String phoneNumber) async {
    final response = await _client.get(
      _uri('/rest/v1/users', {
        'phone_number': 'eq.$phoneNumber',
        'select': '*',
        'limit': '1',
      }),
      headers: _headers,
    );
    final users = _list(response, UserProfile.fromJson);
    return users.isEmpty ? null : users.first;
  }

  List<T> _list<T>(
      http.Response response, T Function(Map<String, dynamic>) map) {
    _check(response);
    final decoded = jsonDecode(response.body) as List;
    return decoded
        .whereType<Map>()
        .map((item) => map(Map<String, dynamic>.from(item)))
        .toList();
  }

  T _single<T>(http.Response response, T Function(Map<String, dynamic>) map) {
    final list = _list(response, map);
    if (list.isEmpty) throw StateError('Supabase returned no rows.');
    return list.first;
  }

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw StateError('Supabase HTTP ${response.statusCode}: ${response.body}');
  }
}

class WeatherClient {
  WeatherClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<WeatherForecast> daily(double lat, double lng) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lng',
      'daily':
          'temperature_2m_max,temperature_2m_min,uv_index_max,precipitation_sum',
      'timezone': 'auto',
    });
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Weather HTTP ${response.statusCode}: ${response.body}');
    }
    return WeatherForecast.fromJson(jsonDecode(response.body));
  }
}

class DataGovMandiClient {
  DataGovMandiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _resourceId = '9ef84268-d588-465a-a308-a864a43d0070';

  final http.Client _client;

  Future<List<MandiPriceRecord>> prices({
    required String commodity,
    String? state,
    String? district,
    int limit = 100,
  }) async {
    final query = <String, String>{
      'api-key': AppConfig.dataGovApiKey,
      'format': 'json',
      'limit': '$limit',
    };
    final cleanCommodity = commodity.trim();
    final cleanState = state?.trim();
    final cleanDistrict = district?.trim();
    if (cleanCommodity.isNotEmpty) {
      query['filters[commodity]'] = cleanCommodity;
    }
    if (cleanState != null && cleanState.isNotEmpty) {
      query['filters[state]'] = cleanState;
    }
    if (cleanDistrict != null && cleanDistrict.isNotEmpty) {
      query['filters[district]'] = cleanDistrict;
    }

    final uri = Uri.https('api.data.gov.in', '/resource/$_resourceId', query);
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Mandi HTTP ${response.statusCode}: ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final records = decoded['records'] as List? ?? const [];
    return records
        .whereType<Map>()
        .map((item) => MandiPriceRecord.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((item) => item.modalPrice > 0)
        .toList();
  }
}

class FarmlandRepository {
  FarmlandRepository(this._api, this._store);

  final SupabaseRestClient _api;
  final LocalStore _store;
  final _uuid = const Uuid();

  List<Farmland> cached(int userId) => _store.getCachedFarmlands(userId);

  Future<List<Farmland>> refresh(int userId) async {
    final farms = await _api.getFarmlands(userId);
    await _store.cacheFarmlands(userId, farms);
    return farms;
  }

  Future<Farmland> save({
    required int userId,
    String? id,
    required String name,
    required String soilType,
    required List<CropItem> crops,
    required double lat,
    required double lng,
    required List<BoundaryPoint> boundary,
    required double heatIndex,
    // New rich metadata fields
    String? irrigationType,
    String? waterSource,
    String? terrainType,
    double? elevation,
    String? farmingPractice,
    String? previousCrop,
    double? soilPH,
    String? landOwnership,
    String? nearestMarket,
    int? farmAge,
  }) async {
    final local = Farmland(
      id: id ?? _uuid.v4(),
      userId: userId,
      name: name.isBlank ? 'New Farmland' : name,
      crops: crops,
      soilType: soilType.isBlank ? 'Unknown' : soilType,
      locationLat: lat,
      locationLng: lng,
      boundaryPoints: boundary,
      heatIndex: heatIndex,
      syncStatus: 'PENDING',
      irrigationType: irrigationType,
      waterSource: waterSource,
      terrainType: terrainType,
      elevation: elevation,
      farmingPractice: farmingPractice,
      previousCrop: previousCrop,
      soilPH: soilPH,
      landOwnership: landOwnership,
      nearestMarket: nearestMarket,
      farmAge: farmAge,
    );
    await _store.upsertCachedFarmland(local);

    try {
      final synced = id == null
          ? await _api.createFarmland(local)
          : await _api.updateFarmland(local);
      await _store.upsertCachedFarmland(synced);
      return synced;
    } catch (_) {
      return local;
    }
  }

  Future<void> delete(int userId, String id) async {
    await _store.deleteCachedFarmland(userId, id);
    try {
      await _api.deleteFarmland(id);
    } catch (_) {
      // Keep local deletion optimistic. A production queue should retry this.
    }
  }
}

extension _StringBlank on String {
  bool get isBlank => trim().isEmpty;
}
