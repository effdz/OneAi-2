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
      print('🔐 Auth valid: ${_pb.authStore.isValid}');
      print('👤 Current user: ${_pb.authStore.model?.id}');
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

      final authRecord = await _pb.authWithPassword('users', email, password);
      print('✅ PocketBase login successful: ${authRecord.data['username']}');
      print('🔐 Auth token: ${_pb.authStore.token}');
      print('👤 User ID: ${authRecord.id}');

      return UserModel(
        id: authRecord.id,
        username: authRecord.data['username'] ?? '',
        email: authRecord.data['email'] ?? '',
        lastLogin: DateTime.now(),
        avatarUrl: authRecord.data['avatar_url'],
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

      final record = await _pb.collection('users').create(userData);
      print('✅ PocketBase registration successful: ${record.data['username']}');

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
      _pb.authStore.clear();
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

      print('☁️ Fetching conversations for user: $userId');
      print('🔐 Current auth user: ${currentUserId}');
      print('🔐 Auth valid: ${isAuthenticated}');

      // Use the authenticated user's ID if available, otherwise use provided userId
      final targetUserId = currentUserId ?? userId;
      print('🎯 Target user ID: $targetUserId');

      final records = await _pb.collection('conversations').getList(
        page: 1,
        perPage: 50,
        filter: 'user_id = "$targetUserId" && is_archived != true',
        sort: '-updated',
      );

      print('☁️ PocketBase returned ${records.length} conversations');

      final conversations = <ConversationModel>[];

      for (final record in records) {
        try {
          print('☁️ Processing conversation: ${record.id}');
          print('   - Title: ${record.data['title']}');
          print('   - User ID: ${record.data['user_id']}');
          print('   - Chatbot ID: ${record.data['chatbot_id']}');
          print('   - Created: ${record.created}');
          print('   - Updated: ${record.updated}');

          // Get message count for this conversation
          final messageCount = await _getMessageCount(record.id);
          print('   - Message count: $messageCount');

          conversations.add(ConversationModel(
            id: record.id,
            userId: record.data['user_id'] ?? '',
            chatbotId: record.data['chatbot_id'] ?? '',
            title: record.data['title'] ?? 'Untitled',
            createdAt: record.created,
            updatedAt: record.updated,
            isArchived: record.data['is_archived'] ?? false,
            messageCount: messageCount,
          ));
        } catch (e) {
          print('❌ Error processing conversation ${record.id}: $e');
        }
      }

      print('✅ Successfully processed ${conversations.length} conversations');
      return conversations;
    } catch (e) {
      print('❌ Error getting conversations from PocketBase: $e');
      print('   Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Get message count for a conversation
  Future<int> _getMessageCount(String conversationId) async {
    try {
      final records = await _pb.collection('messages').getList(
        page: 1,
        perPage: 1,
        filter: 'conversation_id = "$conversationId"',
      );
      return records.length;
    } catch (e) {
      print('❌ Error getting message count for $conversationId: $e');
      return 0;
    }
  }

  /// Create conversation
  Future<String> createConversation(String userId, String chatbotId, String title) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      // Use the authenticated user's ID if available
      final targetUserId = currentUserId ?? userId;
      print('☁️ Creating conversation for user: $targetUserId');

      final data = {
        'user_id': targetUserId,
        'chatbot_id': chatbotId,
        'title': title,
        'is_archived': false,
      };

      final record = await _pb.collection('conversations').create(data);
      print('✅ Created conversation: ${record.id}');
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

      print('☁️ Fetching messages for conversation: $conversationId');

      final records = await _pb.collection('messages').getList(
        page: 1,
        perPage: 100,
        filter: 'conversation_id = "$conversationId"',
        sort: 'created',
      );

      print('☁️ Found ${records.length} messages');

      final messages = <MessageModel>[];

      for (final record in records) {
        try {
          messages.add(MessageModel(
            id: record.id,
            text: record.data['content'] ?? '',
            isUser: record.data['is_user'] ?? false,
            timestamp: record.created,
            tokenCount: record.data['token_count'] ?? 0,
          ));
        } catch (e) {
          print('❌ Error processing message ${record.id}: $e');
        }
      }

      print('✅ Successfully processed ${messages.length} messages');
      return messages;
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

      print('☁️ Creating message in conversation: $conversationId');

      final data = {
        'conversation_id': conversationId,
        'content': message.text,
        'is_user': message.isUser,
        'token_count': message.text.split(' ').length,
      };

      final record = await _pb.collection('messages').create(data);
      print('✅ Created message: ${record.id}');
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
      print('✅ Deleted conversation: $conversationId');
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
      print('✅ Updated conversation title: $conversationId');
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
      print('✅ Archived conversation: $conversationId');
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
        page: 1,
        perPage: 1,
        filter: 'email = "$email"',
      );

      return records.isNotEmpty;
    } catch (e) {
      print('❌ Error checking email: $e');
      return false;
    }
  }
}
