import 'package:flutter/material.dart';
import 'package:oneai/models/chatbot_model.dart';
import 'package:oneai/services/api/huggingface_api.dart';
import 'package:oneai/services/api/openai_api.dart';
import 'package:oneai/services/api/gemini_api.dart';
import 'package:oneai/services/api/mistral_api.dart';
import 'package:oneai/services/api/deepinfra_api.dart';
import 'package:oneai/services/api/openrouter_api.dart';

class ChatbotService {
  static List<ChatbotModel> getChatbots() {
    return [
      const ChatbotModel(
        id: 'openai',
        name: 'OpenAI Assistant',
        description: 'Powered by OpenAI\'s GPT models',
        icon: Icons.auto_awesome,
        color: Color(0xFF10A37F),
        apiType: 'openai',
      ),
      const ChatbotModel(
        id: 'gemini',
        name: 'Gemini',
        description: 'Google\'s Gemini AI assistant',
        icon: Icons.psychology,
        color: Color(0xFF4285F4),
        apiType: 'gemini',
      ),
      const ChatbotModel(
        id: 'mistral',
        name: 'Mistral AI',
        description: 'Powerful open-weight models',
        icon: Icons.air,
        color: Color(0xFF7C3AED),
        apiType: 'mistral',
      ),
      const ChatbotModel(
        id: 'deepinfra-llama',
        name: 'Llama 2 (DeepInfra)',
        description: 'Meta\'s Llama 2 via DeepInfra',
        icon: Icons.memory,
        color: Color(0xFFFF6B6B),
        apiType: 'deepinfra',
      ),
      const ChatbotModel(
        id: 'openrouter-claude',
        name: 'Claude (OpenRouter)',
        description: 'Anthropic\'s Claude via OpenRouter',
        icon: Icons.router,
        color: Color(0xFF00A3E1),
        apiType: 'openrouter',
      ),
      const ChatbotModel(
        id: 'openrouter-mixtral',
        name: 'Mixtral (OpenRouter)',
        description: 'Mixtral 8x7B via OpenRouter',
        icon: Icons.hub,
        color: Color(0xFFFF9800),
        apiType: 'openrouter',
      ),
      const ChatbotModel(
        id: 'huggingface',
        name: 'Hugging Face',
        description: 'Open-source AI models',
        icon: Icons.hub,
        color: Color(0xFFFFD21E),
        apiType: 'huggingface',
      ),
    ];
  }

  static Future<String> getChatbotResponse(String chatbotId, String message) async {
    switch (chatbotId) {
      case 'openai':
        return await OpenAIApi.getResponse(message);
      case 'gemini':
        return await GeminiApi.getResponse(message);
      case 'mistral':
        return await MistralApi.getResponse(message);
      case 'deepinfra-llama':
        return await DeepInfraApi.getResponse(message, model: 'meta-llama/Llama-2-70b-chat-hf');
      case 'openrouter-claude':
        return await OpenRouterApi.getResponse(message, model: 'anthropic/claude-3-opus');
      case 'openrouter-mixtral':
        return await OpenRouterApi.getResponse(message, model: 'mistralai/mixtral-8x7b-instruct');
      case 'huggingface':
        return await HuggingFaceApi.getResponse(message, 'gpt2');
      default:
        throw Exception('Unknown chatbot ID');
    }
  }
}
