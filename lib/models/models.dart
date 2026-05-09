import 'dart:convert';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String phoneNumber;
  final int createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        phoneNumber: json['phone_number'] as String? ?? '',
        createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone_number': phoneNumber,
        'created_at': createdAt,
      };
}

class CropItem {
  const CropItem({
    required this.name,
    this.coveragePercent = 0,
    this.growthStage,
    this.sowingDate,
    this.variety,
    this.quantity,
  });

  final String name;

  /// Percentage of total field area covered by this crop (0-100).
  final double coveragePercent;

  /// Current growth stage: seedling | vegetative | flowering | harvest_ready
  final String? growthStage;

  /// ISO date string of sowing date, e.g. '2026-01-15'
  final String? sowingDate;

  /// Specific seed variety name
  final String? variety;

  /// Legacy quantity field kept for backward compatibility with old data.
  final String? quantity;

  factory CropItem.fromJson(Map<String, dynamic> json) {
    // Backward compat: if coverage_percent is missing, try to parse from
    // quantity string or default to 0.
    double coverage = (json['coverage_percent'] as num?)?.toDouble() ?? 0;
    if (coverage == 0 && json['quantity'] != null) {
      // Try extracting a number from old quantity strings like "60%" or "2 acres"
      final match =
          RegExp(r'(\d+(?:\.\d+)?)').firstMatch(json['quantity'] as String);
      if (match != null && (json['quantity'] as String).contains('%')) {
        coverage = double.tryParse(match.group(1)!) ?? 0;
      }
    }
    return CropItem(
      name: json['name'] as String? ?? '',
      coveragePercent: coverage,
      growthStage: json['growth_stage'] as String?,
      sowingDate: json['sowing_date'] as String?,
      variety: json['variety'] as String?,
      quantity: json['quantity'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'coverage_percent': coveragePercent,
        if (growthStage != null) 'growth_stage': growthStage,
        if (sowingDate != null) 'sowing_date': sowingDate,
        if (variety != null) 'variety': variety,
      };

  CropItem copyWith({
    String? name,
    double? coveragePercent,
    String? growthStage,
    String? sowingDate,
    String? variety,
  }) {
    return CropItem(
      name: name ?? this.name,
      coveragePercent: coveragePercent ?? this.coveragePercent,
      growthStage: growthStage ?? this.growthStage,
      sowingDate: sowingDate ?? this.sowingDate,
      variety: variety ?? this.variety,
    );
  }

  /// Human-readable coverage summary using total area in hectares.
  String coverageSummary(double totalAreaHa) {
    if (coveragePercent <= 0) return 'Not set';
    final areaHa = totalAreaHa * coveragePercent / 100;
    return '${coveragePercent.toStringAsFixed(0)}% (~${areaHa.toStringAsFixed(2)} ha)';
  }
}

/// Available growth stage options for crops.
const cropGrowthStages = [
  'seedling',
  'vegetative',
  'flowering',
  'fruiting',
  'harvest_ready',
];

/// Human-readable labels for growth stages.
String growthStageLabel(String? stage) {
  switch (stage) {
    case 'seedling':
      return 'Seedling';
    case 'vegetative':
      return 'Vegetative';
    case 'flowering':
      return 'Flowering';
    case 'fruiting':
      return 'Fruiting';
    case 'harvest_ready':
      return 'Harvest Ready';
    default:
      return 'Not set';
  }
}

class BoundaryPoint {
  const BoundaryPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory BoundaryPoint.fromJson(Map<String, dynamic> json) => BoundaryPoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

/// Available irrigation types for dropdown selection.
const irrigationTypes = [
  'rainfed',
  'drip',
  'sprinkler',
  'flood',
  'canal',
  'manual',
];

/// Available water sources for dropdown selection.
const waterSources = [
  'well',
  'borewell',
  'river',
  'rain_only',
  'canal',
  'pond',
  'tank',
];

/// Available terrain types for dropdown selection.
const terrainTypes = [
  'flat',
  'gentle_slope',
  'hilly',
  'valley',
  'coastal',
];

/// Available farming practices for dropdown selection.
const farmingPractices = [
  'conventional',
  'organic',
  'mixed',
  'natural',
  'integrated',
];

/// Available land ownership types for dropdown selection.
const landOwnershipTypes = [
  'owned',
  'leased',
  'shared',
  'community',
];

/// Human-readable label for enum-like string values.
String enumLabel(String? value) {
  if (value == null || value.isEmpty) return 'Not set';
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class Farmland {
  const Farmland({
    required this.id,
    required this.userId,
    required this.name,
    required this.crops,
    required this.locationLat,
    required this.locationLng,
    this.soilType,
    this.boundaryPoints = const [],
    this.heatIndex = 0,
    this.syncStatus = 'SYNCED',
    // New rich metadata fields
    this.irrigationType,
    this.waterSource,
    this.terrainType,
    this.elevation,
    this.farmingPractice,
    this.previousCrop,
    this.soilPH,
    this.landOwnership,
    this.nearestMarket,
    this.farmAge,
  });

  final String id;
  final int userId;
  final String name;
  final List<CropItem> crops;
  final String? soilType;
  final double locationLat;
  final double locationLng;
  final List<BoundaryPoint> boundaryPoints;
  final double heatIndex;
  final String syncStatus;

  // New fields for richer AI reports.
  /// Irrigation method: rainfed | drip | sprinkler | flood | canal | manual
  final String? irrigationType;

  /// Primary water source: well | borewell | river | rain_only | canal | pond | tank
  final String? waterSource;

  /// Terrain type: flat | gentle_slope | hilly | valley | coastal
  final String? terrainType;

  /// Elevation in meters (auto-captured from GPS altitude)
  final double? elevation;

  /// Farming practice: conventional | organic | mixed | natural | integrated
  final String? farmingPractice;

  /// Last season's primary crop (for crop rotation insights)
  final String? previousCrop;

  /// Soil pH level (1.0-14.0).
  final double? soilPH;

  /// Land ownership: owned | leased | shared | community
  final String? landOwnership;

  /// Nearest market/town name for post-harvest logistics
  final String? nearestMarket;

  /// Number of years this land has been farmed
  final int? farmAge;

  factory Farmland.fromJson(Map<String, dynamic> json) {
    final cropsJson = json['crops'];
    final boundaryJson = json['boundary_points'];
    return Farmland(
      id: json['id'] as String,
      userId: (json['user_id'] as num).toInt(),
      name: json['name'] as String? ?? 'Unnamed farm',
      crops: _listOfMaps(cropsJson).map(CropItem.fromJson).toList(),
      soilType: json['soil_type'] as String?,
      locationLat: (json['location_lat'] as num).toDouble(),
      locationLng: (json['location_lng'] as num).toDouble(),
      boundaryPoints:
          _listOfMaps(boundaryJson).map(BoundaryPoint.fromJson).toList(),
      heatIndex: (json['heat_index'] as num?)?.toDouble() ?? 0,
      syncStatus: json['sync_status'] as String? ?? 'SYNCED',
      // New fields
      irrigationType: json['irrigation_type'] as String?,
      waterSource: json['water_source'] as String?,
      terrainType: json['terrain_type'] as String?,
      elevation: (json['elevation'] as num?)?.toDouble(),
      farmingPractice: json['farming_practice'] as String?,
      previousCrop: json['previous_crop'] as String?,
      soilPH: (json['soil_ph'] as num?)?.toDouble(),
      landOwnership: json['land_ownership'] as String?,
      nearestMarket: json['nearest_market'] as String?,
      farmAge: (json['farm_age'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'crops': crops.map((e) => e.toJson()).toList(),
        'soil_type': soilType,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'boundary_points': boundaryPoints.map((e) => e.toJson()).toList(),
        'heat_index': heatIndex,
        // Omit null optional fields to keep payload small.
        if (irrigationType != null) 'irrigation_type': irrigationType,
        if (waterSource != null) 'water_source': waterSource,
        if (terrainType != null) 'terrain_type': terrainType,
        if (elevation != null) 'elevation': elevation,
        if (farmingPractice != null) 'farming_practice': farmingPractice,
        if (previousCrop != null) 'previous_crop': previousCrop,
        if (soilPH != null) 'soil_ph': soilPH,
        if (landOwnership != null) 'land_ownership': landOwnership,
        if (nearestMarket != null) 'nearest_market': nearestMarket,
        if (farmAge != null) 'farm_age': farmAge,
      };

  Farmland copyWith({
    String? id,
    int? userId,
    String? name,
    List<CropItem>? crops,
    String? soilType,
    double? locationLat,
    double? locationLng,
    List<BoundaryPoint>? boundaryPoints,
    double? heatIndex,
    String? syncStatus,
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
  }) {
    return Farmland(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      crops: crops ?? this.crops,
      soilType: soilType ?? this.soilType,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      boundaryPoints: boundaryPoints ?? this.boundaryPoints,
      heatIndex: heatIndex ?? this.heatIndex,
      syncStatus: syncStatus ?? this.syncStatus,
      irrigationType: irrigationType ?? this.irrigationType,
      waterSource: waterSource ?? this.waterSource,
      terrainType: terrainType ?? this.terrainType,
      elevation: elevation ?? this.elevation,
      farmingPractice: farmingPractice ?? this.farmingPractice,
      previousCrop: previousCrop ?? this.previousCrop,
      soilPH: soilPH ?? this.soilPH,
      landOwnership: landOwnership ?? this.landOwnership,
      nearestMarket: nearestMarket ?? this.nearestMarket,
      farmAge: farmAge ?? this.farmAge,
    );
  }
}

class PestAlert {
  const PestAlert({
    required this.id,
    required this.timestamp,
    required this.cropName,
    required this.pestType,
    required this.severity,
    required this.locationLat,
    required this.locationLng,
  });

  final int id;
  final int timestamp;
  final String cropName;
  final String pestType;
  final String severity;
  final double locationLat;
  final double locationLng;

  factory PestAlert.fromJson(Map<String, dynamic> json) => PestAlert(
        id: (json['id'] as num).toInt(),
        timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
        cropName: json['crop_name'] as String? ?? '',
        pestType: json['pest_type'] as String? ?? '',
        severity: json['severity'] as String? ?? '',
        locationLat: (json['location_lat'] as num?)?.toDouble() ?? 0,
        locationLng: (json['location_lng'] as num?)?.toDouble() ?? 0,
      );
}

class CropHealthIssue {
  const CropHealthIssue({
    required this.id,
    required this.userId,
    required this.farmlandId,
    required this.farmlandName,
    required this.cropName,
    required this.symptomTags,
    required this.description,
    required this.issueType,
    required this.severity,
    required this.confidence,
    required this.diagnosis,
    required this.immediateAction,
    required this.organicTreatment,
    required this.chemicalTreatment,
    required this.weatherAdvice,
    required this.followUpAt,
    required this.createdAt,
    this.locationLat,
    this.locationLng,
    this.status = 'OPEN',
  });

  final String id;
  final int userId;
  final String farmlandId;
  final String farmlandName;
  final String cropName;
  final List<String> symptomTags;
  final String description;
  final String issueType;
  final String severity;
  final double confidence;
  final String diagnosis;
  final String immediateAction;
  final String organicTreatment;
  final String chemicalTreatment;
  final String weatherAdvice;
  final int followUpAt;
  final int createdAt;
  final double? locationLat;
  final double? locationLng;
  final String status;

  factory CropHealthIssue.fromJson(Map<String, dynamic> json) =>
      CropHealthIssue(
        id: json['id'] as String? ?? '',
        userId: (json['user_id'] as num?)?.toInt() ?? 0,
        farmlandId: json['farmland_id'] as String? ?? '',
        farmlandName: json['farmland_name'] as String? ?? 'Farmland',
        cropName: json['crop_name'] as String? ?? 'Crop',
        symptomTags:
            List<String>.from(json['symptom_tags'] as List? ?? const []),
        description: json['description'] as String? ?? '',
        issueType: json['issue_type'] as String? ?? 'Observation',
        severity: json['severity'] as String? ?? 'Moderate',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.55,
        diagnosis: json['diagnosis'] as String? ?? 'Diagnosis unavailable.',
        immediateAction: json['immediate_action'] as String? ??
            'Scout the crop again in daylight.',
        organicTreatment:
            json['organic_treatment'] as String? ?? 'Use local organic IPM.',
        chemicalTreatment: json['chemical_treatment'] as String? ??
            'Use chemical controls only with local label guidance.',
        weatherAdvice:
            json['weather_advice'] as String? ?? 'Check weather before spray.',
        followUpAt: (json['follow_up_at'] as num?)?.toInt() ?? 0,
        createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
        locationLat: (json['location_lat'] as num?)?.toDouble(),
        locationLng: (json['location_lng'] as num?)?.toDouble(),
        status: json['status'] as String? ?? 'OPEN',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'farmland_id': farmlandId,
        'farmland_name': farmlandName,
        'crop_name': cropName,
        'symptom_tags': symptomTags,
        'description': description,
        'issue_type': issueType,
        'severity': severity,
        'confidence': confidence,
        'diagnosis': diagnosis,
        'immediate_action': immediateAction,
        'organic_treatment': organicTreatment,
        'chemical_treatment': chemicalTreatment,
        'weather_advice': weatherAdvice,
        'follow_up_at': followUpAt,
        'created_at': createdAt,
        if (locationLat != null) 'location_lat': locationLat,
        if (locationLng != null) 'location_lng': locationLng,
        'status': status,
      };

  CropHealthIssue copyWith({
    String? id,
    int? userId,
    String? farmlandId,
    String? farmlandName,
    String? cropName,
    List<String>? symptomTags,
    String? description,
    String? issueType,
    String? severity,
    double? confidence,
    String? diagnosis,
    String? immediateAction,
    String? organicTreatment,
    String? chemicalTreatment,
    String? weatherAdvice,
    int? followUpAt,
    int? createdAt,
    double? locationLat,
    double? locationLng,
    String? status,
  }) {
    return CropHealthIssue(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      farmlandId: farmlandId ?? this.farmlandId,
      farmlandName: farmlandName ?? this.farmlandName,
      cropName: cropName ?? this.cropName,
      symptomTags: symptomTags ?? this.symptomTags,
      description: description ?? this.description,
      issueType: issueType ?? this.issueType,
      severity: severity ?? this.severity,
      confidence: confidence ?? this.confidence,
      diagnosis: diagnosis ?? this.diagnosis,
      immediateAction: immediateAction ?? this.immediateAction,
      organicTreatment: organicTreatment ?? this.organicTreatment,
      chemicalTreatment: chemicalTreatment ?? this.chemicalTreatment,
      weatherAdvice: weatherAdvice ?? this.weatherAdvice,
      followUpAt: followUpAt ?? this.followUpAt,
      createdAt: createdAt ?? this.createdAt,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      status: status ?? this.status,
    );
  }
}

class DailyForecast {
  const DailyForecast({
    required this.time,
    required this.maxTemp,
    required this.minTemp,
    this.uvIndex,
    this.precipitation,
  });

  final List<String> time;
  final List<double> maxTemp;
  final List<double> minTemp;
  final List<double>? uvIndex;
  final List<double>? precipitation;

  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
        time: List<String>.from(json['time'] as List? ?? const []),
        maxTemp: _doubleList(json['temperature_2m_max']),
        minTemp: _doubleList(json['temperature_2m_min']),
        uvIndex: _nullableDoubleList(json['uv_index_max']),
        precipitation: _nullableDoubleList(json['precipitation_sum']),
      );
}

class WeatherForecast {
  const WeatherForecast({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.daily,
  });

  final double latitude;
  final double longitude;
  final String timezone;
  final DailyForecast daily;

  factory WeatherForecast.fromJson(Map<String, dynamic> json) =>
      WeatherForecast(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timezone: json['timezone'] as String? ?? 'auto',
        daily: DailyForecast.fromJson(json['daily'] as Map<String, dynamic>),
      );
}

class CropAnalysis {
  const CropAnalysis({
    required this.cropName,
    required this.sustainabilityColor,
    required this.riskReasoning,
    required this.bestYieldingVariety,
  });

  final String cropName;
  final String sustainabilityColor;
  final String riskReasoning;
  final String bestYieldingVariety;

  factory CropAnalysis.fromJson(Map<String, dynamic> json) => CropAnalysis(
        cropName: json['cropName'] as String? ?? 'Crop',
        sustainabilityColor: json['sustainabilityColor'] as String? ?? 'Green',
        riskReasoning:
            json['riskReasoning'] as String? ?? 'Analysis unavailable.',
        bestYieldingVariety: json['bestYieldingVariety'] as String? ??
            'Locally recommended certified seed',
      );

  Map<String, dynamic> toJson() => {
        'cropName': cropName,
        'sustainabilityColor': sustainabilityColor,
        'riskReasoning': riskReasoning,
        'bestYieldingVariety': bestYieldingVariety,
      };
}

class MandiPriceRecord {
  const MandiPriceRecord({
    required this.state,
    required this.district,
    required this.market,
    required this.commodity,
    required this.variety,
    required this.grade,
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
  });

  final String state;
  final String district;
  final String market;
  final String commodity;
  final String variety;
  final String grade;
  final String arrivalDate;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;

  factory MandiPriceRecord.fromJson(Map<String, dynamic> json) {
    return MandiPriceRecord(
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      market: json['market']?.toString() ?? '',
      commodity: json['commodity']?.toString() ?? '',
      variety: json['variety']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      arrivalDate: json['arrival_date']?.toString() ?? '',
      minPrice: _jsonDouble(json['min_price']),
      maxPrice: _jsonDouble(json['max_price']),
      modalPrice: _jsonDouble(json['modal_price']),
    );
  }

  Map<String, dynamic> toJson() => {
        'state': state,
        'district': district,
        'market': market,
        'commodity': commodity,
        'variety': variety,
        'grade': grade,
        'arrival_date': arrivalDate,
        'min_price': minPrice,
        'max_price': maxPrice,
        'modal_price': modalPrice,
      };
}

class MarketplaceListing {
  const MarketplaceListing({
    required this.id,
    required this.userId,
    required this.listingType,
    required this.title,
    this.description,
    this.cropType,
    this.quantity,
    this.price,
    this.status = 'active',
    this.ownerName,
    this.createdAt,
  });

  final String id;
  final int userId;
  final String listingType;
  final String title;
  final String? description;
  final String? cropType;
  final String? quantity;
  final double? price;
  final String status;
  final String? ownerName;
  final DateTime? createdAt;

  bool get isLabor => listingType.toLowerCase().contains('labor');

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    final owner = json['users'];
    return MarketplaceListing(
      id: json['id']?.toString() ?? '',
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      listingType: json['listing_type']?.toString() ?? 'machinery',
      title: json['title']?.toString() ?? 'Untitled listing',
      description: json['description']?.toString(),
      cropType: json['crop_type']?.toString(),
      quantity: json['quantity']?.toString(),
      price: json['price'] == null ? null : _jsonDouble(json['price']),
      status: json['status']?.toString() ?? 'active',
      ownerName: owner is Map ? owner['name']?.toString() : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'listing_type': listingType,
        'title': title,
        if (description != null) 'description': description,
        if (cropType != null) 'crop_type': cropType,
        if (quantity != null) 'quantity': quantity,
        if (price != null) 'price': price,
        'status': status,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}

class ComprehensiveReport {
  const ComprehensiveReport({
    required this.cropAnalysis,
    required this.weeklyRisks,
    required this.yieldTimeline,
    required this.expertSuggestions,
    required this.smartActionWindow,
  });

  final List<CropAnalysis> cropAnalysis;
  final String weeklyRisks;
  final String yieldTimeline;
  final List<String> expertSuggestions;
  final String smartActionWindow;

  factory ComprehensiveReport.fromJson(Map<String, dynamic> json) =>
      ComprehensiveReport(
        cropAnalysis: _listOfMaps(json['cropAnalysis'])
            .map(CropAnalysis.fromJson)
            .toList(),
        weeklyRisks:
            json['weeklyRisks'] as String? ?? 'Risk assessment unavailable.',
        yieldTimeline:
            json['yieldTimeline'] as String? ?? 'Timeline unavailable.',
        expertSuggestions:
            List<String>.from(json['expertSuggestions'] as List? ?? const []),
        smartActionWindow: json['smartActionWindow'] as String? ??
            'Action window unavailable.',
      );

  Map<String, dynamic> toJson() => {
        'cropAnalysis': cropAnalysis.map((e) => e.toJson()).toList(),
        'weeklyRisks': weeklyRisks,
        'yieldTimeline': yieldTimeline,
        'expertSuggestions': expertSuggestions,
        'smartActionWindow': smartActionWindow,
      };
}

List<Map<String, dynamic>> _listOfMaps(dynamic value) {
  final decoded = value is String ? jsonDecode(value) : value;
  if (decoded is! List) return const [];
  return decoded
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

List<double> _doubleList(dynamic value) =>
    List<num>.from(value as List? ?? const [])
        .map((e) => e.toDouble())
        .toList();

double _jsonDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

List<double>? _nullableDoubleList(dynamic value) =>
    value == null ? null : _doubleList(value);
