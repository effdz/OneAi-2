import 'package:flutter/material.dart';
import 'package:oneai/models/message_model.dart';
import 'package:oneai/models/conversation_model.dart';
import 'package:oneai/services/chatbot_service.dart';
import 'package:oneai/services/database_service.dart';
import 'package:oneai/services/pocketbase_service.dart';
import 'package:oneai/services/storage_manager.dart';
import 'package:oneai/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final PocketBaseService _pbService = PocketBaseService();
  final StorageManager _storageManager = StorageManager();

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

  // Load user conversations based on current storage type
  Future<void> loadConversations() async {
    _isLoadingConversations = true;
    notifyListeners();

    try {
      final userId = await AuthService.getUserId();
      if (userId != null) {
        // Check current storage type and load accordingly
        if (_storageManager.currentStorage == StorageType.pocketbase) {
          await _loadConversationsFromPocketBase(userId);
        } else if (_storageManager.currentStorage == StorageType.hybrid) {
          await _loadConversationsHybrid(userId);
        } else {
          await _loadConversationsFromLocal(userId);
        }
      }
    } catch (e) {
      print('Error loading conversations: $e');
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> _loadConversationsFromLocal(String userId) async {
    _conversations = await _dbService.getUserConversations(userId);
    print('📱 Loaded ${_conversations.length} conversations from local storage');
  }

  Future<void> _loadConversationsFromPocketBase(String userId) async {
    try {
      // PocketBaseService.getUserConversations returns List<ConversationModel>
      _conversations = await _pbService.getUserConversations(userId);
      print('☁️ Loaded ${_conversations.length} conversations from PocketBase');
    } catch (e) {
      print('❌ Error loading from PocketBase, falling back to local: $e');
      await _loadConversationsFromLocal(userId);
    }
  }

  Future<void> _loadConversationsHybrid(String userId) async {
    try {
      // Try PocketBase first, fallback to local
      await _loadConversationsFromPocketBase(userId);
    } catch (e) {
      await _loadConversationsFromLocal(userId);
    }
  }

  // Start new chat
  Future<void> startNewChat(String chatbotId) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      _currentChatbotId = chatbotId;

      // Create conversation based on storage type
      if (_storageManager.currentStorage == StorageType.pocketbase) {
        final conversationId = await _pbService.createConversation(userId, chatbotId, 'New Conversation');
        _currentConversationId = conversationId;
        print('☁️ Created conversation in PocketBase: $conversationId');
      } else {
        _currentConversationId = await _dbService.createConversation(
            userId, chatbotId, 'New Conversation');
      }

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

      // Load messages based on storage type
      if (_storageManager.currentStorage == StorageType.pocketbase) {
        await _loadMessagesFromPocketBase(conversationId);
      } else {
        _currentMessages = await _dbService.getConversationMessages(conversationId);
      }

      // Get chatbot ID from conversation
      final conversation = _conversations.firstWhere(
            (conv) => conv.id == conversationId,
        orElse: () => _conversations.isNotEmpty ? _conversations.first : ConversationModel(
          id: conversationId,
          userId: '',
          chatbotId: 'default',
          title: 'Unknown',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isArchived: false,
          messageCount: 0,
        ),
      );
      _currentChatbotId = conversation.chatbotId;

      notifyListeners();
    } catch (e) {
      print('Error loading conversation: $e');
    }
  }

  Future<void> _loadMessagesFromPocketBase(String conversationId) async {
    try {
      // PocketBaseService.getConversationMessages returns List<MessageModel>
      _currentMessages = await _pbService.getConversationMessages(conversationId);
      print('☁️ Loaded ${_currentMessages.length} messages from PocketBase');
    } catch (e) {
      print('❌ Error loading messages from PocketBase: $e');
      _currentMessages = [];
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

      // Save user message based on storage type
      await _saveMessage(userMessage);

      // Update conversation title if it's the first message
      if (_currentMessages.length == 1) {
        final title = text.length > 30 ? '${text.substring(0, 30)}...' : text;
        await _updateConversationTitle(title);
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

      // Save bot message
      await _saveMessage(botMessage);

      // Record usage analytics
      await _recordUsage(userId, 2, text.split(' ').length + response.split(' ').length);

    } catch (e) {
      // Handle error
      final errorMessage = MessageModel(
        id: const Uuid().v4(),
        text: 'Sorry, I encountered an error. Please try again later.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      _currentMessages.add(errorMessage);

      // Save error message
      if (_currentConversationId != null) {
        await _saveMessage(errorMessage);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveMessage(MessageModel message) async {
    if (_currentConversationId == null) return;

    try {
      if (_storageManager.currentStorage == StorageType.pocketbase) {
        await _pbService.createMessage(_currentConversationId!, message);
        print('☁️ Message saved to PocketBase');
      } else {
        await _dbService.insertMessage(_currentConversationId!, message);
        print('📱 Message saved to local storage');
      }
    } catch (e) {
      print('❌ Error saving message: $e');
    }
  }

  Future<void> _updateConversationTitle(String title) async {
    if (_currentConversationId == null) return;

    try {
      if (_storageManager.currentStorage == StorageType.pocketbase) {
        await _pbService.pb.collection('conversations').update(_currentConversationId!, {
          'title': title,
        });
        print('☁️ Conversation title updated in PocketBase');
      } else {
        await _dbService.updateConversationTitle(_currentConversationId!, title);
        print('📱 Conversation title updated in local storage');
      }
    } catch (e) {
      print('❌ Error updating conversation title: $e');
    }
  }

  Future<void> _recordUsage(String userId, int messageCount, int tokenUsage) async {
    try {
      if (_storageManager.currentStorage == StorageType.pocketbase) {
        await _pbService.pb.collection('usage_analytics').create({
          'user_id': userId,
          'chatbot_id': _currentChatbotId,
          'message_count': messageCount,
          'token_usage': tokenUsage,
          'date': DateTime.now().toIso8601String().split('T')[0],
        });
        print('☁️ Usage recorded in PocketBase');
      } else {
        await _dbService.recordUsage(userId, _currentChatbotId, messageCount, tokenUsage);
        print('📱 Usage recorded in local storage');
      }
    } catch (e) {
      print('❌ Error recording usage: $e');
    }
  }

  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      if (_storageManager.currentStorage == StorageType.pocketbase) {
        await _pbService.pb.collection('conversations').delete(conversationId);
        print('☁️ Conversation deleted from PocketBase');
      } else {
        await _dbService.deleteConversation(conversationId);
        print('📱 Conversation deleted from local storage');
      }

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
      if (_storageManager.currentStorage == StorageType.pocketbase) {
        await _pbService.pb.collection('conversations').update(conversationId, {
          'is_archived': true,
        });
        print('☁️ Conversation archived in PocketBase');
      } else {
        await _dbService.archiveConversation(conversationId);
        print('📱 Conversation archived in local storage');
      }

      await loadConversations();
      notifyListeners();
    } catch (e) {
      print('Error archiving conversation: $e');
    }
  }

  // Update conversation title
  Future<void> updateConversationTitle(String conversationId, String title) async {
    try {
      if (_storageManager.currentStorage == StorageType.pocketbase) {
        await _pbService.pb.collection('conversations').update(conversationId, {
          'title': title,
        });
        print('☁️ Conversation title updated in PocketBase');
      } else {
        await _dbService.updateConversationTitle(conversationId, title);
        print('📱 Conversation title updated in local storage');
      }

      await loadConversations(); // Refresh conversations list
      notifyListeners();
    } catch (e) {
      print('Error updating conversation title: $e');
    }
  }

  // Clear current chat
  void clearCurrentChat() {
    _currentMessages = [];
    _currentConversationId = null;
    _currentChatbotId = '';
    notifyListeners();
  }

  void initChat(String chatbotId) {
    _currentChatbotId = chatbotId;
    _currentMessages = [];
    notifyListeners();
  }

  void clearChat(String chatbotId) {
    _currentMessages = [];
    notifyListeners();
  }

  // Search messages
  Future<List<Map<String, dynamic>>> searchMessages(String query) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return [];

      if (_storageManager.currentStorage == StorageType.pocketbase) {
        // TODO: Implement PocketBase search
        return [];
      } else {
        return await _dbService.searchMessages(userId, query);
      }
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

      if (_storageManager.currentStorage == StorageType.pocketbase) {
        // TODO: Implement PocketBase stats
        return {};
      } else {
        return await _dbService.getUserStats(userId);
      }
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

      if (_storageManager.currentStorage == StorageType.pocketbase) {
        // TODO: Implement PocketBase export
        return {};
      } else {
        return await _dbService.exportUserData(userId);
      }
    } catch (e) {
      print('Error exporting user data: $e');
      return {};
    }
  }

  // Cleanup old data
  Future<void> cleanupOldData() async {
    try {
      if (_storageManager.currentStorage == StorageType.pocketbase) {
        // TODO: Implement PocketBase cleanup
      } else {
        await _dbService.cleanupOldData();
      }
      await loadConversations();
    } catch (e) {
      print('Error cleaning up old data: $e');
    }
  }
}
