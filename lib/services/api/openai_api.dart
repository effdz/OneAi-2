import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIApi {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // Note: In a real app, you would get this from secure storage or environment variables
  static String? _apiKey;

  static void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  static Future<String> getResponse(String message) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      // For demo purposes, return a placeholder response
      return "Please set your OpenAI API key in the settings to use this chatbot.";
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful assistant.'},
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      // For demo purposes, return a placeholder response
      return "I'm having trouble connecting to OpenAI. Please check your internet connection and API key.";
    }
  }
}
