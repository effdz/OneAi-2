import 'package:oneai/services/pocketbase_client.dart';
import 'package:oneai/models/user_model.dart';
import 'package:oneai/models/conversation_model.dart';
import 'package:oneai/models/message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  late PocketBaseClient _pb;
  bool _initialized = false;
  String _baseUrl = 'http://localhost:8090';

  PocketBaseClient get pb => _pb;
  bool get isInitialized => _initialized;
  String get baseUrl => _baseUrl;

  /// Initialize PocketBase connection
  Future<void> initialize({String? customUrl}) async {
    try {
      if (customUrl != null) {
        _baseUrl = customUrl;
        // Save custom URL to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pocketbase_url', customUrl);
      } else {
        // Load saved URL from preferences
        final prefs = await SharedPreferences.getInstance();
        _baseUrl = prefs.getString('pocketbase_url') ?? 'http://localhost:8090';
      }

      _pb = PocketBaseClient(_baseUrl);

      // Load saved auth data
      await _pb.loadAuthFromStorage();

      _initialized = true;

      print('✅ PocketBase initialized with URL: $_baseUrl');
    } catch (e) {
      print('❌ Error initializing PocketBase: $e');
      _initialized = false;
      rethrow;
    }
  }

  /// Check if PocketBase server is reachable
  Future<bool> checkConnection() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      // Try to get health status
      final response = await _pb.health.check();
      print('✅ PocketBase connection successful: $response');
      return true;
    } catch (e) {
      print('❌ PocketBase connection failed: $e');
      return false;
    }
  }

  /// Check if collections exist
  Future<bool> checkCollectionsExist() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final collections = ['users', 'conversations', 'messages', 'usage_analytics'];

      for (final collectionName in collections) {
        try {
          await _pb.collection(collectionName).getList(perPage: 1);
          print('✅ Collection "$collectionName" exists');
        } catch (e) {
          print('❌ Collection "$collectionName" not found: $e');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('❌ Error checking collections: $e');
      return false;
    }
  }

  /// Get current user ID if authenticated
  String? get currentUserId {
    try {
      return _pb.authStore.model?.id;
    } catch (e) {
      return null;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    try {
      return _pb.authStore.isValid;
    } catch (e) {
      return false;
    }
  }

  /// Login with email and password
  Future<UserModel> login(String email, String password) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final user = await _pb.authWithPassword('users', email, password);
      print('✅ PocketBase login successful: ${user.data['username']}');

      return UserModel(
        id: user.id,
        username: user.data['username'] ?? '',
        email: user.data['email'] ?? '',
        lastLogin: DateTime.now(),
        avatarUrl: user.data['avatar_url'],
      );
    } catch (e) {
      print('❌ PocketBase login failed: $e');
      rethrow;
    }
  }

  /// Register new user
  Future<UserModel> register(String username, String email, String password) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      // Create user record
      final userData = {
        'username': username,
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'is_active': true,
      };

      final user = await _pb.collection('users').create(userData);
      print('✅ PocketBase registration successful: ${user.data['username']}');

      // Auto login after registration
      return await login(email, password);
    } catch (e) {
      print('❌ PocketBase registration failed: $e');
      rethrow;
    }
  }

  /// Logout from PocketBase
  Future<void> logout() async {
    try {
      await _pb.authLogout();
      print('✅ PocketBase logout successful');
    } catch (e) {
      print('❌ PocketBase logout error: $e');
    }
  }

  /// Update base URL and reinitialize
  Future<bool> updateBaseUrl(String newUrl) async {
    try {
      await initialize(customUrl: newUrl);
      return await checkConnection();
    } catch (e) {
      print('❌ Error updating PocketBase URL: $e');
      return false;
    }
  }

  /// Get server info
  Future<Map<String, dynamic>?> getServerInfo() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final health = await _pb.health.check();
      return {
        'url': _baseUrl,
        'status': 'connected',
        'health': health,
        'authenticated': isAuthenticated,
        'user_id': currentUserId,
      };
    } catch (e) {
      return {
        'url': _baseUrl,
        'status': 'disconnected',
        'error': e.toString(),
        'authenticated': false,
        'user_id': null,
      };
    }
  }

  /// Get user conversations
  Future<List<ConversationModel>> getUserConversations(String userId) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final records = await _pb.collection('conversations').getList(
        filter: 'user_id = "$userId"',
        sort: '-updated',
      );

      return records.map((record) => ConversationModel(
        id: record.id,
        userId: record.data['user_id'],
        chatbotId: record.data['chatbot_id'],
        title: record.data['title'],
        createdAt: record.created,
        updatedAt: record.updated,
        isArchived: record.data['is_archived'] ?? false,
        messageCount: 0, // Will be calculated separately
      )).toList();
    } catch (e) {
      print('❌ Error getting conversations: $e');
      return [];
    }
  }

  /// Create conversation
  Future<String> createConversation(String userId, String chatbotId, String title) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final data = {
        'user_id': userId,
        'chatbot_id': chatbotId,
        'title': title,
        'is_archived': false,
      };

      final record = await _pb.collection('conversations').create(data);
      return record.id;
    } catch (e) {
      print('❌ Error creating conversation: $e');
      rethrow;
    }
  }

  /// Get conversation messages
  Future<List<MessageModel>> getConversationMessages(String conversationId) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final records = await _pb.collection('messages').getList(
        filter: 'conversation_id = "$conversationId"',
        sort: 'created',
      );

      return records.map((record) => MessageModel(
        id: record.id,
        text: record.data['content'],
        isUser: record.data['is_user'],
        timestamp: record.created,
        tokenCount: record.data['token_count'],
      )).toList();
    } catch (e) {
      print('❌ Error getting messages: $e');
      return [];
    }
  }

  /// Create message
  Future<void> createMessage(String conversationId, MessageModel message) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final data = {
        'conversation_id': conversationId,
        'content': message.text,
        'is_user': message.isUser,
        'token_count': message.text.split(' ').length,
      };

      await _pb.collection('messages').create(data);
    } catch (e) {
      print('❌ Error creating message: $e');
      rethrow;
    }
  }

  /// Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      await _pb.collection('conversations').delete(conversationId);
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      rethrow;
    }
  }

  /// Update conversation title
  Future<void> updateConversationTitle(String conversationId, String title) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      await _pb.collection('conversations').update(conversationId, {
        'title': title,
      });
    } catch (e) {
      print('❌ Error updating conversation title: $e');
      rethrow;
    }
  }

  /// Archive conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      await _pb.collection('conversations').update(conversationId, {
        'is_archived': true,
      });
    } catch (e) {
      print('❌ Error archiving conversation: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final record = await _pb.collection('users').getOne(userId);

      return UserModel(
        id: record.id,
        username: record.data['username'] ?? '',
        email: record.data['email'] ?? '',
        lastLogin: record.data['last_login'] != null
            ? DateTime.parse(record.data['last_login'])
            : null,
        avatarUrl: record.data['avatar_url'],
      );
    } catch (e) {
      print('❌ Error getting user by ID: $e');
      return null;
    }
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final records = await _pb.collection('users').getList(
        filter: 'email = "$email"',
        perPage: 1,
      );

      return records.isNotEmpty;
    } catch (e) {
      print('❌ Error checking email: $e');
      return false;
    }
  }
}
