import os

file_path = r"e:\Dev\krishi-mitra\make-a-ton\lib\services\ai_services.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Add CropIntelligenceReport
model_code = """
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
  final Map<int, String> farmlandEvaluations;

  factory CropIntelligenceReport.fromJson(Map<String, dynamic> json) {
    final evals = <int, String>{};
    final evalsMap = json['farmlandEvaluations'] as Map<String, dynamic>? ?? {};
    evalsMap.forEach((k, v) {
      final id = int.tryParse(k);
      if (id != null) evals[id] = v.toString();
    });
    return CropIntelligenceReport(
      suitableArea: json['suitableArea']?.toString() ?? 'Details unavailable',
      harvestingInfo: json['harvestingInfo']?.toString() ?? 'Details unavailable',
      marketPriceEstimate: json['marketPriceEstimate']?.toString() ?? 'Price estimate unavailable',
      roiEstimate: json['roiEstimate']?.toString() ?? 'ROI estimate unavailable',
      farmlandEvaluations: evals,
    );
  }
}
"""

if "class CropIntelligenceReport" not in content:
    # Add it before FarmlandIntelligence
    idx = content.find("class FarmlandIntelligence {")
    content = content[:idx] + model_code + "\n" + content[idx:]

# Add analyzeCrop method to FarmlandIntelligence
method_code = """
  Future<CropIntelligenceReport?> analyzeCrop(
    String cropName,
    List<Farmland> userFarms,
    String? userLocation,
  ) async {
    if (!AppConfig.isGroqConfigured) return null;

    final farmsInfo = userFarms.map((f) => 
      'ID: ${f.id}, Name: ${f.name}, Soil: ${f.soilType}, pH: ${f.soilPH}, Terrain: ${f.terrainType}'
    ).join('\\n');

    final prompt = '''
Analyze the crop "$cropName" for a farmer located in ${userLocation ?? 'India'}.
Provide practical agronomic details.

Evaluate suitability for the following user farmlands:
$farmsInfo

Return strict raw JSON with the following keys:
- suitableArea: Best climate and regions for this crop.
- harvestingInfo: Harvesting methods and timeline.
- marketPriceEstimate: Current local price estimates (INR) and market demand.
- roiEstimate: Estimated ROI and profitability per hectare.
- farmlandEvaluations: A JSON object mapping farm ID (as string) to a 1-2 sentence evaluation of whether the crop can be grown there based on its soil, pH, and terrain.
''';

    for (final model in _models) {
      try {
        final response = await _groq.complete(prompt, model: model);
        final cleaned = response.replaceAll(RegExp(r'```json|```'), '').trim();
        final json = jsonDecode(cleaned) as Map<String, dynamic>;
        return CropIntelligenceReport.fromJson(json);
      } catch (e) {
        continue;
      }
    }
    return null;
  }
"""

if "Future<CropIntelligenceReport?> analyzeCrop" not in content:
    idx2 = content.find("Future<ComprehensiveReport> analyze(")
    content = content[:idx2] + method_code + "\n" + content[idx2:]

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
print("Updated ai_services.dart")
