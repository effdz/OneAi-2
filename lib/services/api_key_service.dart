import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oneai/services/api/openai_api.dart';
import 'package:oneai/services/api/gemini_api.dart';
import 'package:oneai/services/api/huggingface_api.dart';
import 'package:oneai/services/api/mistral_api.dart';
import 'package:oneai/services/api/deepinfra_api.dart';
import 'package:oneai/services/api/openrouter_api.dart';

class ApiKeyService {
  static const _storage = FlutterSecureStorage();
  static const _useSecureStorage = true; // Set to false to use SharedPreferences instead

  // API key names
  static const String openaiKey = 'openai_api_key';
  static const String geminiKey = 'gemini_api_key';
  static const String huggingfaceKey = 'huggingface_api_key';
  static const String mistralKey = 'mistral_api_key';
  static const String deepinfraKey = 'deepinfra_api_key';
  static const String openrouterKey = 'openrouter_api_key';

  // Save API key
  static Future<void> saveApiKey(String keyName, String value) async {
    if (_useSecureStorage) {
      await _storage.write(key: keyName, value: value);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyName, value);
    }

    // Update the API services
    _updateApiService(keyName, value);
  }

  // Get API key
  static Future<String> getApiKey(String keyName) async {
    if (_useSecureStorage) {
      return await _storage.read(key: keyName) ?? '';
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyName) ?? '';
    }
  }

  // Load all API keys
  static Future<Map<String, String>> loadAllApiKeys() async {
    final Map<String, String> keys = {};

    keys[openaiKey] = await getApiKey(openaiKey);
    keys[geminiKey] = await getApiKey(geminiKey);
    keys[huggingfaceKey] = await getApiKey(huggingfaceKey);
    keys[mistralKey] = await getApiKey(mistralKey);
    keys[deepinfraKey] = await getApiKey(deepinfraKey);
    keys[openrouterKey] = await getApiKey(openrouterKey);

    // Update all API services
    keys.forEach(_updateApiService);

    return keys;
  }


  // Update API service with key
  static void _updateApiService(String keyName, String value) {
    switch (keyName) {
      case openaiKey:
        OpenAIApi.setApiKey(value);
        break;
      case geminiKey:
        GeminiApi.setApiKey(value);
        break;
      case huggingfaceKey:
        HuggingFaceApi.setApiKey(value);
        break;
      case mistralKey:
        MistralApi.setApiKey(value);
        break;
      case deepinfraKey:
        DeepInfraApi.setApiKey(value);
        break;
      case openrouterKey:
        OpenRouterApi.setApiKey(value);
        break;
    }
  }
}
