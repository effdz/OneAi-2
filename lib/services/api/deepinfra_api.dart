import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepInfraApi {
  static const String _baseUrl = 'https://api.deepinfra.com/v1/inference';

  // Note: In a real app, you would get this from secure storage or environment variables
  static String? _apiKey;

  static void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  static Future<String> getResponse(String message, {String model = 'meta-llama/Llama-2-70b-chat-hf'}) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      // For demo purposes, return a placeholder response
      return "Please set your DeepInfra API key in the settings to use this chatbot.";
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$model'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'input': {
            'messages': [
              {'role': 'system', 'content': 'You are a helpful assistant.'},
              {'role': 'user', 'content': message},
            ]
          },
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['output']['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      // For demo purposes, return a placeholder response
      return "I'm having trouble connecting to DeepInfra. Please check your internet connection and API key.";
    }
  }
}
