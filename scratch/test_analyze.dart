import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final file = File('.env');
  final lines = await file.readAsLines();
  String? apiKey;
  for (var line in lines) {
    if (line.startsWith('GROQ_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey == null || apiKey.isEmpty) {
    print('Error: GROQ_API_KEY not found in .env');
    exit(1);
  }

  final prompt = '''
Analyze this Indian farm with practical agronomy.

LOCATION & TERRAIN
GPS: 12.3, 76.5 | Area: 1.00 ha | Geofence: 4 corners

SOIL & WATER
Soil type: Red | pH: 6.5

CROPS (current season)
- Wheat, sown 2026-01-15

WEATHER CONTEXT
Average high: 30 C, low: 20 C. Rain week: 10 mm.

Heat risk index: 20/100

Return strict raw JSON with keys cropAnalysis, weeklyRisks, yieldTimeline, expertSuggestions, smartActionWindow.
''';

  final models = [
    'openai/gpt-oss-120b',
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
  ];

  for (final model in models) {
    print('Trying model: $model');
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': 'Return strict JSON only.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.25,
          'max_tokens': 1500,
        }),
      );

      print('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('Raw content length: ${content.length}');
        
        final start = content.indexOf('{');
        final end = content.lastIndexOf('}');
        if (start < 0 || end <= start) throw StateError('No JSON in AI output.');
        
        final jsonStr = content.substring(start, end + 1);
        final json = jsonDecode(jsonStr);
        print('Parsed JSON successfully! Keys: ${json.keys}');
        break;
      } else {
        print('Failed. Response: ${response.body}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }
}
