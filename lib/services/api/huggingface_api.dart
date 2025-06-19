import 'dart:convert';
import 'package:http/http.dart' as http;

class HuggingFaceApi {
  static const String _baseUrl = 'https://api-inference.huggingface.co/models/';

  // Note: In a real app, you would get this from secure storage or environment variables
  static String? _apiKey;

  static void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  static Future<String> getResponse(String message, String model) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      // For demo purposes, return a placeholder response
      return "Please set your Hugging Face API key in the settings to use this model.";
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$model'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'inputs': message,
          'parameters': {
            'max_new_tokens': 250,
            'temperature': 0.7,
            'return_full_text': false,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]['generated_text'];
        } else if (data is Map && data.containsKey('generated_text')) {
          return data['generated_text'];
        } else {
          return "I received a response but couldn't parse it correctly.";
        }
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      // For demo purposes, return a placeholder response
      return "I'm having trouble connecting to Hugging Face. Please check your internet connection and API key.";
    }
  }
}
