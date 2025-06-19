import 'package:flutter/material.dart';
import 'package:oneai/models/message_model.dart';
import 'package:oneai/models/conversation_model.dart';
import 'package:oneai/services/chatbot_service.dart';
import 'package:oneai/services/database_service.dart';
import 'package:oneai/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final Map<String, List<MessageModel>> _chatHistory = {};

  List<MessageModel> _currentMessages = [];
  List<ConversationModel> _conversations = [];
  String? _currentConversationId;
  String _currentChatbotId = '';
  bool _isLoading = false;
  bool _isLoadingConversations = false;

  List<MessageModel> get messages => _currentMessages;
  List<ConversationModel> get conversations => _conversations;
  String? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  bool get isLoadingConversations => _isLoadingConversations;

  // Initialize chat provider
  Future<void> initialize() async {
    await loadConversations();
  }

  // Load user conversations
  Future<void> loadConversations() async {
    _isLoadingConversations = true;
    notifyListeners();

    try {
      final userId = await AuthService.getUserId();
      if (userId != null) {
        _conversations = await _dbService.getUserConversations(userId);
      }
    } catch (e) {
      print('Error loading conversations: $e');
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  // Start new chat
  Future<void> startNewChat(String chatbotId) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      _currentChatbotId = chatbotId;
      _currentConversationId = await _dbService.createConversation(
          userId,
          chatbotId,
          'New Conversation'
      );

      _currentMessages = [];
      await loadConversations(); // Refresh conversations list
      notifyListeners();
    } catch (e) {
      print('Error starting new chat: $e');
    }
  }

  // Load existing conversation
  Future<void> loadConversation(String conversationId) async {
    try {
      _currentConversationId = conversationId;
      _currentMessages = await _dbService.getConversationMessages(conversationId);

      // Get chatbot ID from conversation
      final conversation = await _dbService.getConversation(conversationId);
      if (conversation != null) {
        _currentChatbotId = conversation.chatbotId;
      }

      notifyListeners();
    } catch (e) {
      print('Error loading conversation: $e');
    }
  }

  // Send message
  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    try {
      final userId = await AuthService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      // If no current conversation, create one
      if (_currentConversationId == null) {
        await startNewChat(_currentChatbotId);
      }

      final userMessage = MessageModel(
        id: const Uuid().v4(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      );

      // Add user message to UI immediately
      _currentMessages.add(userMessage);
      notifyListeners();

      // Save user message to database
      await _dbService.insertMessage(_currentConversationId!, userMessage);

      // Update conversation title if it's the first message
      if (_currentMessages.length == 1) {
        final title = text.length > 30 ? '${text.substring(0, 30)}...' : text;
        await _dbService.updateConversationTitle(_currentConversationId!, title);
        await loadConversations(); // Refresh to show new title
      }

      // Set loading state
      _isLoading = true;
      notifyListeners();

      // Get response from chatbot
      final response = await ChatbotService.getChatbotResponse(
        _currentChatbotId,
        text,
      );

      final botMessage = MessageModel(
        id: const Uuid().v4(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      // Add bot message to UI
      _currentMessages.add(botMessage);

      // Save bot message to database
      await _dbService.insertMessage(_currentConversationId!, botMessage);

      // Record usage analytics
      await _dbService.recordUsage(
          userId,
          _currentChatbotId,
          2, // user + bot message
          text.split(' ').length + response.split(' ').length
      );

    } catch (e) {
      // Handle error
      final errorMessage = MessageModel(
        id: const Uuid().v4(),
        text: 'Sorry, I encountered an error. Please try again later.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      _currentMessages.add(errorMessage);

      // Save error message to database if conversation exists
      if (_currentConversationId != null) {
        await _dbService.insertMessage(_currentConversationId!, errorMessage);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _dbService.deleteConversation(conversationId);

      // If current conversation is deleted, clear it
      if (_currentConversationId == conversationId) {
        _currentConversationId = null;
        _currentMessages = [];
      }

      await loadConversations();
      notifyListeners();
    } catch (e) {
      print('Error deleting conversation: $e');
    }
  }

  // Archive conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      await _dbService.archiveConversation(conversationId);
      await loadConversations();
      notifyListeners();
    } catch (e) {
      print('Error archiving conversation: $e');
    }
  }

  // Search messages
  Future<List<Map<String, dynamic>>> searchMessages(String query) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return [];

      return await _dbService.searchMessages(userId, query);
    } catch (e) {
      print('Error searching messages: $e');
      return [];
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return {};

      return await _dbService.getUserStats(userId);
    } catch (e) {
      print('Error getting user stats: $e');
      return {};
    }
  }

  // Export user data
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return {};

      return await _dbService.exportUserData(userId);
    } catch (e) {
      print('Error exporting user data: $e');
      return {};
    }
  }

  // Clear current chat
  void clearCurrentChat() {
    _currentMessages = [];
    _currentConversationId = null;
    _currentChatbotId = '';
    notifyListeners();
  }

  // Cleanup old data
  Future<void> cleanupOldData() async {
    try {
      await _dbService.cleanupOldData();
      await loadConversations();
    } catch (e) {
      print('Error cleaning up old data: $e');
    }
  }

  void initChat(String chatbotId) {
    _currentChatbotId = chatbotId;
    if (_chatHistory.containsKey(chatbotId)) {
      _currentMessages = _chatHistory[chatbotId]!;
    } else {
      _currentMessages = [];
      _chatHistory[chatbotId] = _currentMessages;
    }
    notifyListeners();
  }

  void clearChat(String chatbotId) {
    _currentMessages = [];
    _chatHistory[chatbotId] = _currentMessages;
    notifyListeners();
  }

  // Update conversation title
  Future<void> updateConversationTitle(String conversationId, String title) async {
    try {
      await _dbService.updateConversationTitle(conversationId, title);
      await loadConversations(); // Refresh conversations list
      notifyListeners();
    } catch (e) {
      print('Error updating conversation title: $e');
    }
  }
}
