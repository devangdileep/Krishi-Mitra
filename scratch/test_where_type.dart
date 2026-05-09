import 'dart:convert';

List<Map<String, dynamic>> _listOfMaps(dynamic value) {
  if (value is! List) return [];
  return value.whereType<Map<String, dynamic>>().toList();
}

void main() {
  final jsonString = '''
  {
    "cropAnalysis": [
      {
        "cropName": "Wheat",
        "sustainabilityColor": "Green",
        "riskReasoning": "Good",
        "bestYieldingVariety": "HD 2967"
      }
    ]
  }
  ''';
  
  final decoded = jsonDecode(jsonString);
  final list = _listOfMaps(decoded['cropAnalysis']);
  
  print('Result list length: ${list.length}');
  if (list.isNotEmpty) {
    print('First element: ${list[0]}');
  } else {
    print('List is empty! This means whereType failed!');
  }
}
