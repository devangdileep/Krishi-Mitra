import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('theme_refresh_v2') ?? false)) {
      await prefs.setBool('dark_theme_enabled', false);
      await prefs.setBool('theme_refresh_v2', true);
    }
    return LocalStore(prefs);
  }

  bool get darkThemeEnabled => _prefs.getBool('dark_theme_enabled') ?? false;

  Future<void> setDarkThemeEnabled(bool value) =>
      _prefs.setBool('dark_theme_enabled', value);

  bool get onboardingCompleted =>
      _prefs.getBool('onboarding_completed') ?? false;

  Future<void> setOnboardingCompleted(bool value) =>
      _prefs.setBool('onboarding_completed', value);

  String get selectedLanguage =>
      _prefs.getString('selected_language') ?? 'en-IN';

  Future<void> setSelectedLanguage(String value) =>
      _prefs.setString('selected_language', value);

  UserProfile? getLoggedInUser() {
    final raw = _prefs.getString('logged_in_user');
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveLoggedInUser(UserProfile user) =>
      _prefs.setString('logged_in_user', jsonEncode(user.toJson()));

  Future<void> clearLoggedInUser() => _prefs.remove('logged_in_user');

  String? get userLocationName => _prefs.getString('user_location_name');
  Future<void> setUserLocationName(String value) =>
      _prefs.setString('user_location_name', value);

  double? get userLat => _prefs.getDouble('user_lat');
  Future<void> setUserLat(double value) => _prefs.setDouble('user_lat', value);

  double? get userLng => _prefs.getDouble('user_lng');
  Future<void> setUserLng(double value) => _prefs.setDouble('user_lng', value);

  Future<void> clearUserData(int userId) async {
    final keys = _prefs
        .getKeys()
        .where((key) =>
            key == 'logged_in_user' ||
            key == 'farmlands_cache_$userId' ||
            key == 'field_doctor_cases_$userId' ||
            key.startsWith('ai_report_'))
        .toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  List<Farmland> getCachedFarmlands(int userId) {
    final raw = _prefs.getString('farmlands_cache_$userId');
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List;
    return list
        .whereType<Map>()
        .map((e) => Farmland.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> cacheFarmlands(int userId, List<Farmland> farmlands) {
    return _prefs.setString(
      'farmlands_cache_$userId',
      jsonEncode(farmlands.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> upsertCachedFarmland(Farmland farmland) async {
    final current = getCachedFarmlands(farmland.userId).toList();
    final index = current.indexWhere((item) => item.id == farmland.id);
    if (index >= 0) {
      current[index] = farmland;
    } else {
      current.add(farmland);
    }
    await cacheFarmlands(farmland.userId, current);
  }

  Future<void> deleteCachedFarmland(int userId, String farmlandId) async {
    final current = getCachedFarmlands(userId)
        .where((item) => item.id != farmlandId)
        .toList();
    await cacheFarmlands(userId, current);
  }

  List<CropHealthIssue> getFieldDoctorCases(int userId) {
    final raw = _prefs.getString('field_doctor_cases_$userId');
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List;
    return list
        .whereType<Map>()
        .map((item) => CropHealthIssue.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> cacheFieldDoctorCases(
    int userId,
    List<CropHealthIssue> cases,
  ) {
    return _prefs.setString(
      'field_doctor_cases_$userId',
      jsonEncode(cases.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> upsertFieldDoctorCase(CropHealthIssue issue) async {
    final current = getFieldDoctorCases(issue.userId).toList();
    final index = current.indexWhere((item) => item.id == issue.id);
    if (index >= 0) {
      current[index] = issue;
    } else {
      current.insert(0, issue);
    }
    await cacheFieldDoctorCases(issue.userId, current);
  }

  ComprehensiveReport? getAiReport(String cacheKey) {
    final raw = _prefs.getString('ai_report_$cacheKey');
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final expiresAt = json['expiresAt'] as int? ?? 0;
    if (expiresAt <= DateTime.now().millisecondsSinceEpoch) return null;
    return ComprehensiveReport.fromJson(
      json['report'] as Map<String, dynamic>,
    );
  }

  Future<void> cacheAiReport(
    String cacheKey,
    ComprehensiveReport report, {
    Duration ttl = const Duration(hours: 6),
  }) {
    return _prefs.setString(
      'ai_report_$cacheKey',
      jsonEncode({
        'expiresAt': DateTime.now().add(ttl).millisecondsSinceEpoch,
        'report': report.toJson(),
      }),
    );
  }
}
