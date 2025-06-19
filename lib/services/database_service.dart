import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:oneai/models/user_model.dart';
import 'package:oneai/models/message_model.dart';
import 'package:oneai/models/conversation_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Simulate database with SharedPreferences for now
  late SharedPreferences _prefs;
  bool _initialized = false;

  // Initialize database (SharedPreferences for now)
  Future<void> get database async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      print('Database initialized successfully (using SharedPreferences)');
    }
  }

  // Password hashing
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  // User operations
  Future<bool> registerUser(String username, String email, String password) async {
    try {
      await database;
      print('Attempting to register user: $email');

      // Check if user already exists
      final existingUsers = _prefs.getStringList('users') ?? [];
      for (final userJson in existingUsers) {
        final userData = jsonDecode(userJson);
        if (userData['email'] == email.toLowerCase()) {
          print('User already exists: $email');
          throw Exception('Email sudah terdaftar');
        }
      }

      final passwordHash = _hashPassword(password);
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

      // Create user record
      final userData = {
        'id': userId,
        'username': username,
        'email': email.toLowerCase(),
        'password_hash': passwordHash,
        'avatar_url': null,
        'is_active': true,
        'last_login': null,
        'created_at': DateTime.now().toIso8601String(),
      };

      existingUsers.add(jsonEncode(userData));
      await _prefs.setStringList('users', existingUsers);

      print('User registered successfully: $email with ID: $userId');
      return true;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  Future<UserModel?> loginUser(String email, String password) async {
    try {
      await database;
      print('Attempting to login user: $email');

      final users = _prefs.getStringList('users') ?? [];

      for (final userJson in users) {
        final userData = jsonDecode(userJson);
        if (userData['email'] == email.toLowerCase()) {
          final storedHash = userData['password_hash'];

          if (!_verifyPassword(password, storedHash)) {
            print('Invalid password for user: $email');
            return null;
          }

          // Update last login
          userData['last_login'] = DateTime.now().toIso8601String();

          // Update user in storage
          final updatedUsers = users.map((u) {
            final uData = jsonDecode(u);
            if (uData['id'] == userData['id']) {
              return jsonEncode(userData);
            }
            return u;
          }).toList();

          await _prefs.setStringList('users', updatedUsers);

          print('User logged in successfully: $email');
          return UserModel(
            id: userData['id'],
            username: userData['username'],
            email: userData['email'],
            lastLogin: DateTime.now(),
            avatarUrl: userData['avatar_url'],
          );
        }
      }

      print('User not found: $email');
      return null;
    } catch (e) {
      print('Error logging in user: $e');
      return null;
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      await database;
      print('Getting user by ID: $userId');

      final users = _prefs.getStringList('users') ?? [];

      for (final userJson in users) {
        final userData = jsonDecode(userJson);
        if (userData['id'] == userId) {
          print('User found by ID: ${userData['username']}');
          return UserModel(
            id: userData['id'],
            username: userData['username'],
            email: userData['email'],
            lastLogin: userData['last_login'] != null
                ? DateTime.parse(userData['last_login'])
                : null,
            avatarUrl: userData['avatar_url'],
          );
        }
      }

      print('User not found by ID: $userId');
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  Future<bool> emailExists(String email) async {
    try {
      await database;
      final users = _prefs.getStringList('users') ?? [];

      for (final userJson in users) {
        final userData = jsonDecode(userJson);
        if (userData['email'] == email.toLowerCase()) {
          print('Email exists check for $email: true');
          return true;
        }
      }

      print('Email exists check for $email: false');
      return false;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Conversation operations
  Future<String> createConversation(String userId, String chatbotId, String? title) async {
    try {
      await database;
      print('📝 Creating conversation for user: $userId, chatbot: $chatbotId');

      final conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
      final conversations = _prefs.getStringList('conversations') ?? [];

      final conversationData = {
        'id': conversationId,
        'user_id': userId,
        'chatbot_id': chatbotId,
        'title': title ?? 'New Conversation',
        'is_archived': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      conversations.add(jsonEncode(conversationData));
      await _prefs.setStringList('conversations', conversations);

      print('✅ Conversation created: $conversationId');
      print('📊 Total conversations in storage: ${conversations.length}');
      return conversationId;
    } catch (e) {
      print('❌ Error creating conversation: $e');
      rethrow;
    }
  }

  Future<List<ConversationModel>> getUserConversations(String userId) async {
    try {
      await database;
      print('🔍 Getting conversations for user: $userId');

      final conversations = _prefs.getStringList('conversations') ?? [];
      print('📊 Total conversations in storage: ${conversations.length}');

      final userConversations = <ConversationModel>[];

      for (final convJson in conversations) {
        try {
          final convData = jsonDecode(convJson);
          print('🔍 Checking conversation: ${convData['id']} for user: ${convData['user_id']}');

          // Debug: Print the comparison
          print('   - Stored user_id: "${convData['user_id']}"');
          print('   - Looking for user_id: "$userId"');
          print('   - Match: ${convData['user_id'] == userId}');
          print('   - Is archived: ${convData['is_archived']}');

          if (convData['user_id'] == userId && !(convData['is_archived'] ?? false)) {
            // Get message count for this conversation
            final messageCount = await _getMessageCount(convData['id']);
            print('   ✅ Adding conversation: ${convData['title']} with $messageCount messages');

            userConversations.add(ConversationModel(
              id: convData['id'],
              userId: convData['user_id'],
              chatbotId: convData['chatbot_id'],
              title: convData['title'],
              createdAt: DateTime.parse(convData['created_at']),
              updatedAt: DateTime.parse(convData['updated_at']),
              isArchived: convData['is_archived'] ?? false,
              messageCount: messageCount,
            ));
          } else {
            print('   ❌ Skipping conversation (user mismatch or archived)');
          }
        } catch (e) {
          print('❌ Error parsing conversation JSON: $e');
          print('   Raw JSON: $convJson');
        }
      }

      // Sort by updated_at descending
      userConversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      print('✅ Returning ${userConversations.length} conversations for user $userId');
      for (var conv in userConversations) {
        print('   - ${conv.title} (${conv.messageCount} messages) - ${conv.updatedAt}');
      }

      return userConversations;
    } catch (e) {
      print('❌ Error getting conversations: $e');
      return [];
    }
  }

  Future<int> _getMessageCount(String conversationId) async {
    try {
      final messages = _prefs.getStringList('messages') ?? [];
      int count = 0;

      for (final msgJson in messages) {
        try {
          final msgData = jsonDecode(msgJson);
          if (msgData['conversation_id'] == conversationId) {
            count++;
          }
        } catch (e) {
          print('❌ Error parsing message JSON: $e');
        }
      }

      return count;
    } catch (e) {
      print('❌ Error getting message count: $e');
      return 0;
    }
  }

  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      await database;
      print('Getting conversation: $conversationId');

      final conversations = _prefs.getStringList('conversations') ?? [];

      for (final convJson in conversations) {
        final convData = jsonDecode(convJson);
        if (convData['id'] == conversationId) {
          final messageCount = await _getMessageCount(conversationId);

          return ConversationModel(
            id: convData['id'],
            userId: convData['user_id'],
            chatbotId: convData['chatbot_id'],
            title: convData['title'],
            createdAt: DateTime.parse(convData['created_at']),
            updatedAt: DateTime.parse(convData['updated_at']),
            isArchived: convData['is_archived'] ?? false,
            messageCount: messageCount,
          );
        }
      }

      return null;
    } catch (e) {
      print('Error getting conversation: $e');
      return null;
    }
  }

  Future<void> updateConversationTitle(String conversationId, String title) async {
    try {
      await database;
      print('Updating conversation title: $conversationId -> $title');

      final conversations = _prefs.getStringList('conversations') ?? [];
      final updatedConversations = <String>[];

      for (final convJson in conversations) {
        final convData = jsonDecode(convJson);
        if (convData['id'] == conversationId) {
          convData['title'] = title;
          convData['updated_at'] = DateTime.now().toIso8601String();
        }
        updatedConversations.add(jsonEncode(convData));
      }

      await _prefs.setStringList('conversations', updatedConversations);
      print('Conversation title updated successfully');
    } catch (e) {
      print('Error updating conversation title: $e');
    }
  }

  // Message operations
  Future<void> insertMessage(String conversationId, MessageModel message) async {
    try {
      await database;
      print('💬 Inserting message into conversation: $conversationId');

      final messages = _prefs.getStringList('messages') ?? [];

      final messageData = {
        'id': message.id,
        'conversation_id': conversationId,
        'content': message.text,
        'is_user': message.isUser,
        'token_count': message.text.split(' ').length,
        'created_at': message.timestamp.toIso8601String(),
      };

      messages.add(jsonEncode(messageData));
      await _prefs.setStringList('messages', messages);

      // Update conversation updated_at
      await _updateConversationTimestamp(conversationId);

      print('✅ Message inserted successfully');
      print('📊 Total messages in storage: ${messages.length}');
    } catch (e) {
      print('❌ Error inserting message: $e');
    }
  }

  Future<void> _updateConversationTimestamp(String conversationId) async {
    try {
      final conversations = _prefs.getStringList('conversations') ?? [];
      final updatedConversations = <String>[];

      for (final convJson in conversations) {
        final convData = jsonDecode(convJson);
        if (convData['id'] == conversationId) {
          convData['updated_at'] = DateTime.now().toIso8601String();
        }
        updatedConversations.add(jsonEncode(convData));
      }

      await _prefs.setStringList('conversations', updatedConversations);
    } catch (e) {
      print('Error updating conversation timestamp: $e');
    }
  }

  Future<List<MessageModel>> getConversationMessages(String conversationId) async {
    try {
      await database;
      print('Getting messages for conversation: $conversationId');

      final messages = _prefs.getStringList('messages') ?? [];
      final conversationMessages = <MessageModel>[];

      for (final msgJson in messages) {
        final msgData = jsonDecode(msgJson);
        if (msgData['conversation_id'] == conversationId) {
          conversationMessages.add(MessageModel(
            id: msgData['id'],
            text: msgData['content'],
            isUser: msgData['is_user'],
            timestamp: DateTime.parse(msgData['created_at']),
            tokenCount: msgData['token_count'],
          ));
        }
      }

      // Sort by timestamp ascending
      conversationMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      print('Returning ${conversationMessages.length} messages');
      return conversationMessages;
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await database;
      print('Deleting conversation: $conversationId');

      // Delete all messages in the conversation
      final messages = _prefs.getStringList('messages') ?? [];
      final filteredMessages = messages.where((msgJson) {
        final msgData = jsonDecode(msgJson);
        return msgData['conversation_id'] != conversationId;
      }).toList();

      await _prefs.setStringList('messages', filteredMessages);

      // Delete the conversation
      final conversations = _prefs.getStringList('conversations') ?? [];
      final filteredConversations = conversations.where((convJson) {
        final convData = jsonDecode(convJson);
        return convData['id'] != conversationId;
      }).toList();

      await _prefs.setStringList('conversations', filteredConversations);

      print('Conversation deleted successfully');
    } catch (e) {
      print('Error deleting conversation: $e');
    }
  }

  Future<void> archiveConversation(String conversationId) async {
    try {
      await database;
      print('Archiving conversation: $conversationId');

      final conversations = _prefs.getStringList('conversations') ?? [];
      final updatedConversations = <String>[];

      for (final convJson in conversations) {
        final convData = jsonDecode(convJson);
        if (convData['id'] == conversationId) {
          convData['is_archived'] = true;
          convData['updated_at'] = DateTime.now().toIso8601String();
        }
        updatedConversations.add(jsonEncode(convData));
      }

      await _prefs.setStringList('conversations', updatedConversations);
      print('Conversation archived successfully');
    } catch (e) {
      print('Error archiving conversation: $e');
    }
  }

  // Search and analytics methods
  Future<List<Map<String, dynamic>>> searchMessages(String userId, String query) async {
    try {
      await database;

      // Get user's conversations first
      final conversations = _prefs.getStringList('conversations') ?? [];
      final userConversationIds = <String>[];

      for (final convJson in conversations) {
        final convData = jsonDecode(convJson);
        if (convData['user_id'] == userId) {
          userConversationIds.add(convData['id']);
        }
      }

      if (userConversationIds.isEmpty) return [];

      // Search messages
      final messages = _prefs.getStringList('messages') ?? [];
      final searchResults = <Map<String, dynamic>>[];

      for (final msgJson in messages) {
        final msgData = jsonDecode(msgJson);
        if (userConversationIds.contains(msgData['conversation_id']) &&
            msgData['content'].toLowerCase().contains(query.toLowerCase())) {
          searchResults.add({
            'id': msgData['id'],
            'content': msgData['content'],
            'conversation_id': msgData['conversation_id'],
            'created': msgData['created_at'],
          });
        }
      }

      return searchResults;
    } catch (e) {
      print('Error searching messages: $e');
      return [];
    }
  }

  Future<void> recordUsage(String userId, String chatbotId, int messageCount, int tokenUsage) async {
    try {
      await database;

      final usageList = _prefs.getStringList('usage_analytics') ?? [];
      final usageData = {
        'id': 'usage_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': userId,
        'chatbot_id': chatbotId,
        'message_count': messageCount,
        'token_usage': tokenUsage,
        'date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD format
        'created_at': DateTime.now().toIso8601String(),
      };

      usageList.add(jsonEncode(usageData));
      await _prefs.setStringList('usage_analytics', usageList);
    } catch (e) {
      print('Error recording usage: $e');
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      await database;

      // Get total conversations
      final conversations = _prefs.getStringList('conversations') ?? [];
      int totalConversations = 0;

      for (final convJson in conversations) {
        final convData = jsonDecode(convJson);
        if (convData['user_id'] == userId) {
          totalConversations++;
        }
      }

      // Get total messages
      final messages = _prefs.getStringList('messages') ?? [];
      int totalMessages = 0;
      int weeklyMessages = 0;
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      for (final msgJson in messages) {
        final msgData = jsonDecode(msgJson);
        // Check if message belongs to user's conversation
        bool isUserMessage = false;
        for (final convJson in conversations) {
          final convData = jsonDecode(convJson);
          if (convData['user_id'] == userId && convData['id'] == msgData['conversation_id']) {
            isUserMessage = true;
            break;
          }
        }

        if (isUserMessage) {
          totalMessages++;
          final messageDate = DateTime.parse(msgData['created_at']);
          if (messageDate.isAfter(weekAgo)) {
            weeklyMessages++;
          }
        }
      }

      return {
        'total_messages': totalMessages,
        'total_conversations': totalConversations,
        'favorite_bot': null, // Can be implemented later
        'weekly_messages': weeklyMessages,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'total_messages': 0,
        'total_conversations': 0,
        'favorite_bot': null,
        'weekly_messages': 0,
      };
    }
  }

  Future<void> cleanupOldData() async {
    try {
      await database;

      // Delete messages older than 90 days
      final oldDate = DateTime.now().subtract(const Duration(days: 90));
      final messages = _prefs.getStringList('messages') ?? [];
      final filteredMessages = <String>[];

      for (final msgJson in messages) {
        final msgData = jsonDecode(msgJson);
        final messageDate = DateTime.parse(msgData['created_at']);
        if (messageDate.isAfter(oldDate)) {
          filteredMessages.add(msgJson);
        }
      }

      await _prefs.setStringList('messages', filteredMessages);
      print('Cleanup completed: ${messages.length - filteredMessages.length} old messages deleted');
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  Future<void> closeDatabase() async {
    // Nothing to close for SharedPreferences
    print('Database connection closed');
  }

  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      await database;

      // Get user data
      final user = await getUserById(userId);

      // Get conversations
      final conversations = await getUserConversations(userId);

      // Get all messages for user's conversations
      final allMessages = <Map<String, dynamic>>[];
      for (final conv in conversations) {
        final messages = await getConversationMessages(conv.id);
        for (final msg in messages) {
          allMessages.add({
            'conversation_id': conv.id,
            'conversation_title': conv.title,
            'message': msg.toJson(),
          });
        }
      }

      return {
        'exported_at': DateTime.now().toIso8601String(),
        'user': user?.toJson(),
        'conversations': conversations.map((c) => c.toJson()).toList(),
        'messages': allMessages,
        'total_conversations': conversations.length,
        'total_messages': allMessages.length,
      };
    } catch (e) {
      print('Error exporting user data: $e');
      return {
        'exported_at': DateTime.now().toIso8601String(),
        'error': 'Failed to export data: $e',
      };
    }
  }
}
