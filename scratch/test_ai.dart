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

  print('Testing Groq API with key: ${apiKey.substring(0, 10)}...');

  final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'llama-3.1-8b-instant',
      'messages': [
        {'role': 'user', 'content': 'Say hello in 2 words.'}
      ]
    }),
  );

  print('Status code: ${response.statusCode}');
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Response: ${data['choices'][0]['message']['content']}');
    print('Groq API is WORKING perfectly!');
  } else {
    print('Error response: ${response.body}');
  }
}
