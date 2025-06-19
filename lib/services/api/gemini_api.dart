import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiApi {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  // Note: In a real app, you would get this from secure storage or environment variables
  static String? _apiKey;

  static void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  static Future<String> getResponse(String message) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      // For demo purposes, return a placeholder response
      return "Please set your Google AI API key in the settings to use Gemini.";
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': message}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 500,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      // For demo purposes, return a placeholder response
      return "I'm having trouble connecting to Gemini. Please check your internet connection and API key.";
    }
  }
}
