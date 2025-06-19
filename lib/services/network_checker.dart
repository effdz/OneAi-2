import 'dart:io';
import 'package:http/http.dart' as http;

class NetworkChecker {
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('❌ No internet connection: $e');
      return false;
    }
  }

  static Future<bool> canReachAPI(String url) async {
    try {
      final response = await http.head(
        Uri.parse(url),
        headers: {'User-Agent': 'OneAI-Mobile/1.0.0'},
      ).timeout(const Duration(seconds: 10));

      print('✅ API reachable: $url (${response.statusCode})');
      return response.statusCode < 500;
    } catch (e) {
      print('❌ API unreachable: $url - $e');
      return false;
    }
  }

  static Future<Map<String, bool>> checkAllAPIs() async {
    final apis = {
      'OpenAI': 'https://api.openai.com',
      'Gemini': 'https://generativelanguage.googleapis.com',
      'Mistral': 'https://api.mistral.ai',
      'DeepInfra': 'https://api.deepinfra.com',
      'OpenRouter': 'https://openrouter.ai',
      'HuggingFace': 'https://api-inference.huggingface.co',
    };

    final results = <String, bool>{};

    for (final entry in apis.entries) {
      results[entry.key] = await canReachAPI(entry.value);
    }

    return results;
  }
}
