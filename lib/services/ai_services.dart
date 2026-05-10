import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/models.dart';
import 'local_store.dart';

class SupportedLanguage {
  const SupportedLanguage({
    required this.code,
    required this.displayName,
    required this.englishName,
    required this.idlePrompt,
    required this.listeningPrompt,
    required this.thinkingPrompt,
    required this.answerLabel,
  });

  final String code;
  final String displayName;
  final String englishName;
  final String idlePrompt;
  final String listeningPrompt;
  final String thinkingPrompt;
  final String answerLabel;
}

class SupportedLanguages {
  static const all = [
    SupportedLanguage(
      code: 'en-IN',
      displayName: 'English (India)',
      englishName: 'English',
      idlePrompt: 'Tap the mic and ask your farm question',
      listeningPrompt: 'Listening...',
      thinkingPrompt: 'Checking the best advice...',
      answerLabel: 'Krishi Mitra AI',
    ),
    SupportedLanguage(
      code: 'hi-IN',
      displayName: 'Hindi',
      englishName: 'Hindi',
      idlePrompt: 'Tap the mic and ask your farm question',
      listeningPrompt: 'Listening...',
      thinkingPrompt: 'Checking the best advice...',
      answerLabel: 'Krishi Mitra AI',
    ),
    SupportedLanguage(
      code: 'ml-IN',
      displayName: 'Malayalam',
      englishName: 'Malayalam',
      idlePrompt: 'Tap the mic and ask your farm question',
      listeningPrompt: 'Listening...',
      thinkingPrompt: 'Checking the best advice...',
      answerLabel: 'Krishi Mitra AI',
    ),
    SupportedLanguage(
      code: 'ta-IN',
      displayName: 'Tamil',
      englishName: 'Tamil',
      idlePrompt: 'Tap the mic and ask your farm question',
      listeningPrompt: 'Listening...',
      thinkingPrompt: 'Checking the best advice...',
      answerLabel: 'Krishi Mitra AI',
    ),
    SupportedLanguage(
      code: 'te-IN',
      displayName: 'Telugu',
      englishName: 'Telugu',
      idlePrompt: 'Tap the mic and ask your farm question',
      listeningPrompt: 'Listening...',
      thinkingPrompt: 'Checking the best advice...',
      answerLabel: 'Krishi Mitra AI',
    ),
    SupportedLanguage(
      code: 'kn-IN',
      displayName: 'Kannada',
      englishName: 'Kannada',
      idlePrompt: 'Tap the mic and ask your farm question',
      listeningPrompt: 'Listening...',
      thinkingPrompt: 'Checking the best advice...',
      answerLabel: 'Krishi Mitra AI',
    ),
  ];

  static SupportedLanguage byCode(String code) =>
      all.firstWhere((item) => item.code == code, orElse: () => all.first);
}

class VoiceAdviceContext {
  const VoiceAdviceContext({
    required this.farms,
    this.userLocationName,
    this.latitude,
    this.longitude,
    this.weather,
    this.mandiRecords = const [],
  });

  final List<Farmland> farms;
  final String? userLocationName;
  final double? latitude;
  final double? longitude;
  final WeatherForecast? weather;
  final List<MandiPriceRecord> mandiRecords;
}

class DecisionEngine {
  DecisionEngine({http.Client? client})
      : _groq = _GroqChatGateway(client ?? http.Client());

  final _GroqChatGateway _groq;
  final _models = const [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768',
  ];

  Future<String> advice(
    String question,
    String languageCode, {
    VoiceAdviceContext? context,
  }) async {
    if (!AppConfig.isGroqConfigured) {
      return 'Groq is not configured. Add GROQ_API_KEY in .env or pass it with --dart-define.';
    }

    final languageName = SupportedLanguages.byCode(languageCode).englishName;
    final contextPrompt = _voiceContextPrompt(context);
    final systemPrompt = '''
You are Dr. Krishi Mitra, a senior Indian agronomist, soil scientist, crop protection advisor, and mandi-aware farm planning assistant.
Reply only in $languageName. If the selected language is regional, use that native script only.

Think before answering. Use the provided farm, weather, crop, and mandi context. If a fact is not provided, say it is uncertain instead of inventing it.
Give scientific but farmer-friendly reasoning: crop physiology, soil pH, water stress, pest or disease cycle, nutrient logic, weather timing, and economics when relevant.
For pesticides, fertilizers, or medicines, stay safe: do not give exact high-risk dosage unless locally verified; recommend soil test, label directions, and extension officer confirmation.
For voice output, use natural spoken wording with no markdown. Keep the answer practical and clear: quick answer, why, what to do today, and what to monitor.
Prefer 120-180 words. Use Celsius, millimetres, hectares, and INR per quintal.
''';

    try {
      return await _groq.complete(
        models: _models,
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {
            'role': 'user',
            'content': '''
FARMER QUESTION
$question

AVAILABLE CONTEXT
$contextPrompt

Answer as if speaking directly to the farmer. Analyze the question first, then give the best practical recommendation.
''',
          },
        ],
        temperature: 0.35,
        maxTokens: 1200,
      );
    } catch (error) {
      return 'I could not reach the AI model right now. Last error: $error';
    }
  }

  String _voiceContextPrompt(VoiceAdviceContext? context) {
    if (context == null) {
      return 'No farm profile, weather, or mandi context was provided.';
    }

    final coordinates = context.latitude == null || context.longitude == null
        ? 'Coordinates unavailable'
        : '${context.latitude!.toStringAsFixed(4)}, ${context.longitude!.toStringAsFixed(4)}';
    final farmLines = context.farms.isEmpty
        ? 'No saved farms.'
        : context.farms.map((farm) {
            final area = estimateAreaHectares(farm.boundaryPoints);
            final crops = farm.crops.isEmpty
                ? 'no current crops'
                : farm.crops
                    .map((crop) =>
                        '${crop.name}${crop.coveragePercent > 0 ? " ${crop.coveragePercent.toStringAsFixed(0)}%" : ""}${crop.growthStage != null ? " at ${enumLabel(crop.growthStage)} stage" : ""}')
                    .join(', ');
            return [
              'Farm: ${farm.name}',
              'Area: ${area > 0 ? "${area.toStringAsFixed(2)} ha" : "unmapped"}',
              'GPS: ${farm.locationLat.toStringAsFixed(4)}, ${farm.locationLng.toStringAsFixed(4)}',
              'Soil: ${farm.soilType ?? "unknown"}',
              if (farm.soilPH != null) 'pH: ${farm.soilPH!.toStringAsFixed(1)}',
              if (farm.irrigationType != null)
                'Irrigation: ${enumLabel(farm.irrigationType)}',
              if (farm.waterSource != null)
                'Water source: ${enumLabel(farm.waterSource)}',
              if (farm.terrainType != null)
                'Terrain: ${enumLabel(farm.terrainType)}',
              if (farm.previousCrop != null)
                'Previous crop: ${farm.previousCrop}',
              if (farm.nearestMarket != null)
                'Nearest market: ${farm.nearestMarket}',
              'Crops: $crops',
            ].join('; ');
          }).join('\n');

    final mandiLines = context.mandiRecords.isEmpty
        ? 'No live mandi rows available for this question.'
        : context.mandiRecords.take(8).map((record) {
            return '${record.commodity} at ${record.market}, ${record.district}: modal INR ${record.modalPrice.toStringAsFixed(0)}/qtl, range INR ${record.minPrice.toStringAsFixed(0)}-${record.maxPrice.toStringAsFixed(0)}/qtl, ${record.arrivalDate}.';
          }).join('\n');

    return '''
User location: ${context.userLocationName ?? 'not set'}
User GPS: $coordinates
Weather: ${_weatherSummary(context.weather)}
Saved farms:
$farmLines
Latest mandi context:
$mandiLines
''';
  }

  String _weatherSummary(WeatherForecast? weather) {
    if (weather == null) return 'Weather forecast unavailable.';
    final max = weather.daily.maxTemp;
    final min = weather.daily.minTemp;
    final rain = weather.daily.precipitation ?? const <double>[];
    final avgHigh = _average(max);
    final avgLow = _average(min);
    return 'Average high: ${avgHigh?.toStringAsFixed(0) ?? "unknown"} C, low: ${avgLow?.toStringAsFixed(0) ?? "unknown"} C. Rain this week: ${rain.fold<double>(0, (sum, value) => sum + value).toStringAsFixed(0)} mm.';
  }

  double? _average(List<double>? values) {
    if (values == null || values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

class CropIntelligenceReport {
  const CropIntelligenceReport({
    required this.suitableArea,
    required this.harvestingInfo,
    required this.marketPriceEstimate,
    required this.roiEstimate,
    required this.farmlandEvaluations,
  });

  final String suitableArea;
  final String harvestingInfo;
  final String marketPriceEstimate;
  final String roiEstimate;
  final Map<String, String> farmlandEvaluations;

  factory CropIntelligenceReport.fromJson(Map<String, dynamic> json) {
    final evals = <String, String>{};
    final evalsMap = json['farmlandEvaluations'] as Map<String, dynamic>? ?? {};
    evalsMap.forEach((k, v) {
      evals[k.toString()] = v.toString();
    });
    return CropIntelligenceReport(
      suitableArea: json['suitableArea']?.toString() ?? 'Details unavailable',
      harvestingInfo:
          json['harvestingInfo']?.toString() ?? 'Details unavailable',
      marketPriceEstimate: json['marketPriceEstimate']?.toString() ??
          'Price estimate unavailable',
      roiEstimate:
          json['roiEstimate']?.toString() ?? 'ROI estimate unavailable',
      farmlandEvaluations: evals,
    );
  }
}

class FarmlandIntelligence {
  FarmlandIntelligence(this._store, {http.Client? client})
      : _groq = _GroqChatGateway(client ?? http.Client());

  final LocalStore _store;
  final _GroqChatGateway _groq;
  static const _modelVersion = 'flutter-farm-report-v2';
  final _models = const [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768',
  ];

  List<CropHealthIssue> fieldDoctorCases(int userId) =>
      _store.getFieldDoctorCases(userId);

  Future<void> saveFieldDoctorCase(CropHealthIssue issue) =>
      _store.upsertFieldDoctorCase(issue);

  Future<CropHealthIssue> diagnoseFieldIssue({
    required int userId,
    required Farmland farm,
    required String cropName,
    required List<String> symptomTags,
    required String description,
    WeatherForecast? weather,
  }) async {
    final local = _localFieldDoctorIssue(
      userId: userId,
      farm: farm,
      cropName: cropName,
      symptomTags: symptomTags,
      description: description,
      weather: weather,
    );
    if (!AppConfig.isGroqConfigured) return local;

    final prompt = _buildFieldDoctorPrompt(
      farm: farm,
      cropName: cropName,
      symptomTags: symptomTags,
      description: description,
      weather: weather,
    );

    for (final model in _models) {
      try {
        final response = await _groq.complete(
          models: [model],
          messages: [
            {'role': 'system', 'content': 'Return strict JSON only.'},
            {'role': 'user', 'content': prompt},
          ],
          temperature: 0.2,
          maxTokens: 1300,
        );
        final cleaned = response.replaceAll(RegExp(r'```json|```'), '').trim();
        final start = cleaned.indexOf('{');
        final end = cleaned.lastIndexOf('}');
        if (start < 0 || end <= start) continue;
        final json = jsonDecode(cleaned.substring(start, end + 1))
            as Map<String, dynamic>;
        final rawFollowUpDays = (json['followUpDays'] as num?)?.toInt() ?? 3;
        final followUpDays = rawFollowUpDays.clamp(1, 7).toInt();
        final confidence =
            (json['confidence'] as num?)?.toDouble() ?? local.confidence;
        return local.copyWith(
          issueType: json['issueType']?.toString() ?? local.issueType,
          severity: json['severity']?.toString() ?? local.severity,
          confidence: confidence.clamp(0.35, 0.95).toDouble(),
          diagnosis: json['diagnosis']?.toString() ?? local.diagnosis,
          immediateAction:
              json['immediateAction']?.toString() ?? local.immediateAction,
          organicTreatment:
              json['organicTreatment']?.toString() ?? local.organicTreatment,
          chemicalTreatment:
              json['chemicalTreatment']?.toString() ?? local.chemicalTreatment,
          weatherAdvice:
              json['weatherAdvice']?.toString() ?? local.weatherAdvice,
          followUpAt: DateTime.now()
              .add(Duration(days: followUpDays))
              .millisecondsSinceEpoch,
        );
      } catch (_) {
        continue;
      }
    }
    return local;
  }

  Future<CropIntelligenceReport?> analyzeCrop(
    String cropName,
    List<Farmland> userFarms,
    String? userLocation, {
    WeatherForecast? weather,
    double? latitude,
    double? longitude,
  }) async {
    if (!AppConfig.isGroqConfigured) return null;

    final farmsInfo = userFarms
        .map((f) => [
              'ID: ${f.id}',
              'Name: ${f.name}',
              'Area: ${estimateAreaHectares(f.boundaryPoints).toStringAsFixed(2)} ha',
              'Soil: ${f.soilType}',
              'pH: ${f.soilPH}',
              'Terrain: ${f.terrainType}',
              'Irrigation: ${f.irrigationType}',
              'Water source: ${f.waterSource}',
              'Previous crop: ${f.previousCrop}',
              'Nearest market: ${f.nearestMarket}',
            ].join(', '))
        .join('\n');
    final weatherInfo =
        weather == null ? 'Weather unavailable' : _weatherSummary(weather);
    final coordinates = latitude == null || longitude == null
        ? 'Coordinates unavailable'
        : '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

    final prompt = '''
Analyze the crop "$cropName" for an Indian farmer.

USER LOCATION
- Region: ${userLocation ?? 'India'}
- GPS: $coordinates
- Weather cycle: $weatherInfo

The farmer needs a practical decision report: where the crop is suitable, how harvest is done, current local price signal, likely ROI, and whether the crop is suitable for each saved farmland.

Evaluate suitability for the following user farmlands:
$farmsInfo

Return strict raw JSON with the following keys:
- suitableArea: Best climate and regions for this crop.
- harvestingInfo: Harvesting methods and timeline.
- marketPriceEstimate: Current local price estimates in INR using available Indian mandi/MSP context. Mention if only indicative.
- roiEstimate: Estimated ROI, input cost, yield assumptions, and profitability per hectare.
- farmlandEvaluations: A JSON object mapping farm ID (as string) to a 1-2 sentence evaluation of whether the crop can be grown there based on its soil, pH, and terrain.
''';

    for (final model in _models) {
      try {
        final response = await _groq.complete(
          models: [model],
          messages: [
            {'role': 'system', 'content': 'Return strict JSON only.'},
            {'role': 'user', 'content': prompt},
          ],
          temperature: 0.25,
          maxTokens: 1500,
        );
        final cleaned = response.replaceAll(RegExp(r'```json|```'), '').trim();
        final json = jsonDecode(cleaned) as Map<String, dynamic>;
        return CropIntelligenceReport.fromJson(json);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  CropHealthIssue _localFieldDoctorIssue({
    required int userId,
    required Farmland farm,
    required String cropName,
    required List<String> symptomTags,
    required String description,
    required WeatherForecast? weather,
  }) {
    final now = DateTime.now();
    final text = [
      cropName,
      description,
      symptomTags.join(' '),
    ].join(' ').toLowerCase();
    final rain = weather?.daily.precipitation
            ?.take(3)
            .fold<double>(0, (sum, value) => sum + value) ??
        0;
    final avgHigh = _average(weather?.daily.maxTemp);
    var issueType = 'Field stress';
    var severity = 'Moderate';
    var confidence = 0.58;
    var diagnosis =
        'The symptoms suggest mixed crop stress. Check leaves, stems, roots, and nearby plants before treatment.';
    var immediateAction =
        'Mark the affected patch, inspect 10 plants around it, and avoid spraying until the cause is clearer.';
    var organicTreatment =
        'Remove badly affected leaves, improve airflow, and use neem or bio-control only when pest activity is visible.';
    var chemicalTreatment =
        'Use chemical pesticide or fungicide only after confirming the pest or disease and following the product label.';

    if (text.contains('spot') ||
        text.contains('brown') ||
        text.contains('black') ||
        text.contains('fung')) {
      issueType = 'Possible fungal or bacterial leaf spot';
      severity = rain >= 15 ? 'High' : 'Moderate';
      confidence = 0.72;
      diagnosis =
          'Leaf spots with humid or rainy weather often point to fungal or bacterial disease pressure.';
      immediateAction =
          'Avoid overhead irrigation, remove the worst infected leaves, and scout the lower canopy in the morning.';
      organicTreatment =
          'Use a bio-fungicide or copper-based organic option where locally approved, plus better spacing and airflow.';
      chemicalTreatment =
          'If spots are spreading fast, ask the local agri shop/extension officer for a crop-labeled fungicide or bactericide.';
    } else if (text.contains('yellow') ||
        text.contains('chlorosis') ||
        text.contains('pale')) {
      issueType = 'Nutrient or water stress';
      severity = 'Moderate';
      confidence = 0.68;
      diagnosis =
          'Yellowing is commonly linked to nitrogen deficiency, root stress, waterlogging, or iron/zinc shortage.';
      immediateAction =
          'Check soil moisture at root depth, compare older and younger leaves, and inspect roots if possible.';
      organicTreatment =
          'Apply compost tea or well-decomposed compost only after confirming the soil is not waterlogged.';
      chemicalTreatment =
          'Use a soil-test-based nutrient correction. Avoid blanket fertilizer if roots are waterlogged.';
    } else if (text.contains('hole') ||
        text.contains('chew') ||
        text.contains('larva') ||
        text.contains('borer') ||
        text.contains('insect')) {
      issueType = 'Chewing pest or borer activity';
      severity = 'High';
      confidence = 0.76;
      diagnosis =
          'Leaf holes, frass, or stem damage usually indicate active insect feeding.';
      immediateAction =
          'Scout early morning, look under leaves and inside whorls/stems, and estimate how many plants are affected.';
      organicTreatment =
          'Hand-pick larvae where possible and use neem or Bt products when the pest matches the label.';
      chemicalTreatment =
          'Use a crop-labeled insecticide only if the pest crosses local economic threshold levels.';
    } else if (text.contains('wilt') ||
        text.contains('droop') ||
        text.contains('dry')) {
      issueType = 'Water stress or root disease';
      severity = avgHigh != null && avgHigh >= 34 ? 'High' : 'Moderate';
      confidence = 0.7;
      diagnosis =
          'Wilting can come from heat stress, dry soil, root rot, nematodes, or blocked water movement.';
      immediateAction =
          'Check soil moisture before irrigation, split one weak plant to inspect roots, and compare shaded vs open plants.';
      organicTreatment =
          'Improve drainage or mulching depending on soil moisture. Avoid overwatering weak root systems.';
      chemicalTreatment =
          'Do not apply pesticide for wilting until root or pest cause is confirmed.';
    } else if (text.contains('powder') || text.contains('white')) {
      issueType = 'Possible powdery mildew';
      severity = 'Moderate';
      confidence = 0.73;
      diagnosis =
          'White powdery growth on leaves is often powdery mildew, especially in humid nights and dry days.';
      immediateAction =
          'Remove heavily affected leaves, improve sunlight and airflow, and scout new leaves after two days.';
      organicTreatment =
          'Use locally recommended sulfur or bio-fungicide options where safe for the crop.';
      chemicalTreatment =
          'If spreading, use a crop-labeled mildew fungicide and rotate mode of action.';
    }

    final weatherAdvice = rain >= 12
        ? 'Rain is likely or recent, so avoid spraying before rain and focus on drainage and scouting.'
        : avgHigh != null && avgHigh >= 34
            ? 'High heat is likely. Spray only in the cool morning or evening if treatment is truly needed.'
            : 'Weather is workable. Prefer early morning scouting and spray only after confirming the cause.';

    return CropHealthIssue(
      id: 'doctor_${now.millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      userId: userId,
      farmlandId: farm.id,
      farmlandName: farm.name,
      cropName: cropName.trim().isEmpty ? 'Crop' : cropName.trim(),
      symptomTags: symptomTags,
      description: description.trim(),
      issueType: issueType,
      severity: severity,
      confidence: confidence,
      diagnosis: diagnosis,
      immediateAction: immediateAction,
      organicTreatment: organicTreatment,
      chemicalTreatment: chemicalTreatment,
      weatherAdvice: weatherAdvice,
      followUpAt: now.add(const Duration(days: 3)).millisecondsSinceEpoch,
      createdAt: now.millisecondsSinceEpoch,
      locationLat: farm.locationLat,
      locationLng: farm.locationLng,
    );
  }

  String _buildFieldDoctorPrompt({
    required Farmland farm,
    required String cropName,
    required List<String> symptomTags,
    required String description,
    required WeatherForecast? weather,
  }) {
    final area = estimateAreaHectares(farm.boundaryPoints);
    return '''
Act as an Indian crop health field doctor. The farmer needs practical first-aid, not a final lab diagnosis.

FARM
- Name: ${farm.name}
- Crop: $cropName
- Soil: ${farm.soilType ?? 'Unknown'}
- pH: ${farm.soilPH?.toStringAsFixed(1) ?? 'Unknown'}
- Area: ${area > 0 ? '${area.toStringAsFixed(2)} ha' : 'unmapped'}
- Irrigation: ${enumLabel(farm.irrigationType)}
- Water source: ${enumLabel(farm.waterSource)}
- Terrain: ${enumLabel(farm.terrainType)}
- Previous crop: ${farm.previousCrop ?? 'Unknown'}
- Weather: ${_weatherSummary(weather)}

SYMPTOMS
- Tags: ${symptomTags.join(', ')}
- Farmer note: ${description.trim().isEmpty ? 'No extra note.' : description.trim()}

Return strict raw JSON with keys:
- issueType: short likely category.
- severity: Low, Moderate, or High.
- confidence: number from 0.35 to 0.95.
- diagnosis: 2-3 practical sentences.
- immediateAction: what to do today.
- organicTreatment: organic/IPM option.
- chemicalTreatment: chemical option with safety wording, no exact unsafe dosage unless locally verified.
- weatherAdvice: whether to spray/wait based on weather.
- followUpDays: integer 1-7.
''';
  }

  Future<ComprehensiveReport> analyze(
    Farmland farm,
    WeatherForecast? weather,
  ) async {
    final weatherSummary = _weatherSummary(weather);
    final cacheKey = sha256
        .convert(utf8.encode(
            '${farm.id}|${jsonEncode(farm.toJson())}|$weatherSummary|$_modelVersion'))
        .toString()
        .substring(0, 24);

    final cached = _store.getAiReport(cacheKey);
    if (cached != null) {
      return _withFallbackCropAnalysis(cached, farm, weather);
    }

    if (!AppConfig.isGroqConfigured) {
      return instantPreview(farm, weather);
    }

    final prompt = _buildPrompt(farm, weatherSummary);
    for (final model in _models) {
      try {
        final report = _withFallbackCropAnalysis(
            await _callGroq(model, prompt), farm, weather);
        await _store.cacheAiReport(cacheKey, report);
        return report;
      } catch (_) {
        continue;
      }
    }
    return instantPreview(farm, weather);
  }

  ComprehensiveReport instantPreview(Farmland farm, WeatherForecast? weather) {
    final avgHigh = _average(weather?.daily.maxTemp);
    final rain = weather?.daily.precipitation?.fold<double>(0, (a, b) => a + b);
    final heatColor = farm.heatIndex > 70 || (avgHigh ?? 0) > 36
        ? 'Orange'
        : (rain ?? 0) < 8
            ? 'Yellow'
            : 'Green';
    final weatherPhrase = avgHigh == null
        ? 'Weather is limited, so scout before applying inputs.'
        : 'Average high is ${avgHigh.toStringAsFixed(0)} degrees Celsius this week.';
    final irrigationNote = farm.irrigationType != null
        ? ' ${enumLabel(farm.irrigationType)} irrigation is in use.'
        : '';
    final terrainNote = farm.terrainType != null
        ? ' Terrain is ${enumLabel(farm.terrainType)}.'
        : '';
    final area = estimateAreaHectares(farm.boundaryPoints);
    final farmReadinessReason =
        '$weatherPhrase Soil is ${farm.soilType ?? "unknown"}${farm.soilPH != null ? " (pH ${farm.soilPH!.toStringAsFixed(1)})" : ""}.$irrigationNote$terrainNote'
        '${area > 0 ? " Boundary area is ~${area.toStringAsFixed(2)} ha." : " Map the boundary for better area and ROI estimates."}';
    final cropAnalysis = farm.crops.isEmpty
        ? [
            CropAnalysis(
              cropName: 'Farm readiness',
              sustainabilityColor: heatColor,
              riskReasoning:
                  '$farmReadinessReason Add crop coverage to get crop-specific sustainability scoring.',
              bestYieldingVariety:
                  'Select a crop in the Farms tab to compare suitable varieties.',
            ),
          ]
        : farm.crops
            .map(
              (crop) => CropAnalysis(
                cropName: crop.name,
                sustainabilityColor: heatColor,
                riskReasoning:
                    '$weatherPhrase Soil is ${farm.soilType ?? "unknown"}${farm.soilPH != null ? " (pH ${farm.soilPH!.toStringAsFixed(1)})" : ""}.$irrigationNote$terrainNote'
                    '${crop.coveragePercent > 0 && area > 0 ? " Covers ~${(area * crop.coveragePercent / 100).toStringAsFixed(2)} ha (${crop.coveragePercent.toStringAsFixed(0)}%)." : ""}',
                bestYieldingVariety:
                    crop.variety ?? _fallbackVariety(crop.name),
              ),
            )
            .toList();

    return ComprehensiveReport(
      cropAnalysis: cropAnalysis,
      weeklyRisks:
          'Local preview active while AI refreshes. Check leaf undersides and wet patches during morning scouting.${farm.previousCrop != null ? " Previous crop was ${farm.previousCrop}, check for rotation-related soil issues." : ""}',
      yieldTimeline:
          'Keep the crop on its normal local growth schedule. Yield confidence improves after crop stage and boundary are fully mapped.',
      expertSuggestions: [
        'Scout the field early morning and mark stressed patches inside the geofence.',
        'Apply irrigation or fertilizer only after checking soil moisture at multiple points.',
        'Keep a three-day pest note with photos for comparison.',
        if (farm.farmingPractice == 'organic')
          'Use neem-based or bio-pesticides consistent with organic practice.',
        if (farm.terrainType == 'hilly' || farm.terrainType == 'gentle_slope')
          'Watch for topsoil erosion after heavy rain on sloped terrain.',
      ],
      smartActionWindow:
          'Use the next cool morning window for scouting and irrigation checks. Avoid spraying before rain or during midday heat.',
    );
  }

  String _weatherSummary(WeatherForecast? weather) {
    if (weather == null) return 'Weather forecast unavailable.';
    final max = weather.daily.maxTemp;
    final min = weather.daily.minTemp;
    final rain = weather.daily.precipitation ?? const <double>[];
    return 'Average high: ${_average(max)?.toStringAsFixed(0)} C, low: ${_average(min)?.toStringAsFixed(0)} C. Rain week: ${rain.fold<double>(0, (a, b) => a + b).toStringAsFixed(0)} mm.';
  }

  String _buildPrompt(Farmland farm, String weatherSummary) {
    final area = estimateAreaHectares(farm.boundaryPoints);
    final cropLines = farm.crops.isEmpty
        ? '- No current crop coverage added.'
        : farm.crops.map((crop) {
            final parts = <String>[crop.name];
            if (crop.variety != null) parts.add('(${crop.variety} variety)');
            if (crop.coveragePercent > 0) {
              parts.add('${crop.coveragePercent.toStringAsFixed(0)}% coverage');
              if (area > 0) {
                parts.add(
                    '(~${(area * crop.coveragePercent / 100).toStringAsFixed(2)} ha)');
              }
            }
            if (crop.growthStage != null) {
              parts.add('${enumLabel(crop.growthStage)} stage');
            }
            if (crop.sowingDate != null) parts.add('sown ${crop.sowingDate}');
            return '- ${parts.join(', ')}';
          }).join('\n');

    final locationBlock = [
      'GPS: ${farm.locationLat.toStringAsFixed(4)}, ${farm.locationLng.toStringAsFixed(4)}',
      if (farm.elevation != null)
        'Elevation: ${farm.elevation!.toStringAsFixed(0)}m',
      if (farm.terrainType != null) 'Terrain: ${enumLabel(farm.terrainType)}',
      'Area: ${area > 0 ? "${area.toStringAsFixed(2)} ha" : "unmapped"}',
      'Geofence: ${farm.boundaryPoints.length} corners',
    ].join(' | ');

    final soilBlock = [
      'Soil type: ${farm.soilType ?? "Unknown"}',
      if (farm.soilPH != null) 'pH: ${farm.soilPH!.toStringAsFixed(1)}',
      if (farm.irrigationType != null)
        'Irrigation: ${enumLabel(farm.irrigationType)}',
      if (farm.waterSource != null)
        'Water source: ${enumLabel(farm.waterSource)}',
      if (farm.farmingPractice != null)
        'Practice: ${enumLabel(farm.farmingPractice)}${farm.farmAge != null ? " (${farm.farmAge} years)" : ""}',
      if (farm.previousCrop != null) 'Previous crop: ${farm.previousCrop}',
    ].join(' | ');

    final logisticsBlock = [
      if (farm.landOwnership != null)
        'Ownership: ${enumLabel(farm.landOwnership)}',
      if (farm.nearestMarket != null) 'Nearest market: ${farm.nearestMarket}',
    ].join(' | ');

    return '''
Analyze this Indian farm with practical agronomy.

LOCATION & TERRAIN
$locationBlock

SOIL & WATER
$soilBlock

OWNERSHIP & MARKET
${logisticsBlock.isEmpty ? 'Not provided.' : logisticsBlock}

CROPS (current season)
$cropLines

WEATHER CONTEXT
$weatherSummary

Heat risk index: ${farm.heatIndex.toStringAsFixed(0)}/100

Return strict raw JSON with keys cropAnalysis, weeklyRisks, yieldTimeline, expertSuggestions, smartActionWindow.
''';
  }

  Future<ComprehensiveReport> _callGroq(String model, String prompt) async {
    final response = await _groq.complete(
      models: [model],
      messages: [
        {'role': 'system', 'content': 'Return strict JSON only.'},
        {'role': 'user', 'content': prompt},
      ],
      temperature: 0.25,
      maxTokens: 2000,
    );
    final cleaned = response.replaceAll(RegExp(r'```json|```'), '').trim();
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start < 0 || end <= start) throw StateError('No JSON in AI output.');
    return ComprehensiveReport.fromJson(
      jsonDecode(cleaned.substring(start, end + 1)) as Map<String, dynamic>,
    );
  }

  ComprehensiveReport _withFallbackCropAnalysis(
    ComprehensiveReport report,
    Farmland farm,
    WeatherForecast? weather,
  ) {
    if (report.cropAnalysis.isNotEmpty) return report;
    final preview = instantPreview(farm, weather);
    return ComprehensiveReport(
      cropAnalysis: preview.cropAnalysis,
      weeklyRisks: report.weeklyRisks,
      yieldTimeline: report.yieldTimeline,
      expertSuggestions: report.expertSuggestions,
      smartActionWindow: report.smartActionWindow,
    );
  }

  String _fallbackVariety(String cropName) {
    switch (cropName.trim().toLowerCase()) {
      case 'rice':
      case 'paddy':
        return 'Jyothi or Uma certified seed';
      case 'wheat':
        return 'HD 2967 certified seed';
      case 'maize':
      case 'corn':
        return 'HQPM-1 certified seed';
      case 'tomato':
        return 'Arka Rakshak certified seed';
      default:
        return 'Locally recommended certified ${cropName.trim()} seed';
    }
  }

  double? _average(List<double>? values) {
    if (values == null || values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

class _GroqChatGateway {
  const _GroqChatGateway(this._client);

  final http.Client _client;

  Future<String> complete({
    required List<String> models,
    required List<Map<String, String>> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    if (AppConfig.isGroqProxyConfigured) {
      return _completeViaProxy(
        models: models,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    }

    if (!AppConfig.isGroqDirectConfigured) {
      throw StateError('Groq is not configured.');
    }

    var lastError = 'unknown error';
    for (final model in models) {
      try {
        return await _completeDirect(
          model: model,
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      } catch (error) {
        lastError = '$error';
      }
    }
    throw StateError(lastError);
  }

  Future<String> _completeViaProxy({
    required List<String> models,
    required List<Map<String, String>> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    final response = await _client.post(
      Uri.parse(AppConfig.groqProxyEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'apikey': AppConfig.supabaseApiKey,
        'Authorization': 'Bearer ${AppConfig.supabaseApiKey}',
      },
      body: jsonEncode({
        'models': models,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Groq proxy HTTP ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['content'] as String? ?? '';
  }

  Future<String> _completeDirect({
    required String model,
    required List<Map<String, String>> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    final response = await _client.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${AppConfig.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Groq HTTP ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['choices'][0]['message']['content'] as String;
  }
}

double estimateAreaHectares(List<BoundaryPoint> points) {
  if (points.length < 3) return 0;
  final originLat =
      points.map((e) => e.lat).reduce((a, b) => a + b) / points.length;
  const metersPerLat = 111320.0;
  final metersPerLng = 111320.0 * cos(originLat * pi / 180);
  var areaTwice = 0.0;
  for (var i = 0; i < points.length; i++) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    final x1 = current.lng * metersPerLng;
    final y1 = current.lat * metersPerLat;
    final x2 = next.lng * metersPerLng;
    final y2 = next.lat * metersPerLat;
    areaTwice += (x1 * y2) - (x2 * y1);
  }
  return areaTwice.abs() / 2 / 10000;
}
