import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PocketBaseSetup {
  final String baseUrl;
  final String adminEmail;
  final String adminPassword;

  PocketBaseSetup({
    required this.baseUrl,
    required this.adminEmail,
    required this.adminPassword,
  });

  Future<void> setupCollections() async {
    try {
      print('🚀 Starting PocketBase collections setup...');

      // 1. Authenticate as admin
      final authToken = await _authenticateAdmin();
      if (authToken == null) {
        throw Exception('Failed to authenticate as admin');
      }

      // 2. Create collections
      await _createUsersCollection(authToken);
      await _createConversationsCollection(authToken);
      await _createMessagesCollection(authToken);
      await _createUsageAnalyticsCollection(authToken);

      print('✅ All collections created successfully!');

    } catch (e) {
      print('❌ Error setting up collections: $e');
      rethrow;
    }
  }

  Future<String?> _authenticateAdmin() async {
    try {
      print('🔐 Authenticating admin...');

      final response = await http.post(
        Uri.parse('$baseUrl/api/admins/auth-with-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identity': adminEmail,
          'password': adminPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Admin authenticated successfully');
        return data['token'];
      } else {
        print('❌ Admin authentication failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error authenticating admin: $e');
      return null;
    }
  }

  Future<void> _createUsersCollection(String authToken) async {
    print('📝 Creating users collection...');

    final schema = {
      "name": "users",
      "type": "auth",
      "schema": [
        {
          "name": "username",
          "type": "text",
          "required": true,
          "options": {"min": 3, "max": 50}
        },
        {
          "name": "avatar_url",
          "type": "url",
          "required": false,
          "options": {"exceptDomains": [], "onlyDomains": []}
        },
        {
          "name": "is_active",
          "type": "bool",
          "required": false
        },
        {
          "name": "last_login",
          "type": "date",
          "required": false
        }
      ],
      "indexes": [
        "CREATE UNIQUE INDEX idx_users_email ON users (email)",
        "CREATE INDEX idx_users_username ON users (username)"
      ],
      "listRule": "",
      "viewRule": "",
      "createRule": "",
      "updateRule": "id = @request.auth.id",
      "deleteRule": "id = @request.auth.id"
    };

    await _createCollection(authToken, schema);
  }

  Future<void> _createConversationsCollection(String authToken) async {
    print('📝 Creating conversations collection...');

    final schema = {
      "name": "conversations",
      "type": "base",
      "schema": [
        {
          "name": "user_id",
          "type": "relation",
          "required": true,
          "options": {
            "collectionId": "users",
            "cascadeDelete": true,
            "maxSelect": 1
          }
        },
        {
          "name": "chatbot_id",
          "type": "text",
          "required": true,
          "options": {"min": 1, "max": 100}
        },
        {
          "name": "title",
          "type": "text",
          "required": true,
          "options": {"min": 1, "max": 255}
        },
        {
          "name": "is_archived",
          "type": "bool",
          "required": false
        }
      ],
      "indexes": [
        "CREATE INDEX idx_conversations_user_id ON conversations (user_id)",
        "CREATE INDEX idx_conversations_chatbot_id ON conversations (chatbot_id)"
      ],
      "listRule": "user_id = @request.auth.id",
      "viewRule": "user_id = @request.auth.id",
      "createRule": "@request.auth.id != \"\"",
      "updateRule": "user_id = @request.auth.id",
      "deleteRule": "user_id = @request.auth.id"
    };

    await _createCollection(authToken, schema);
  }

  Future<void> _createMessagesCollection(String authToken) async {
    print('📝 Creating messages collection...');

    final schema = {
      "name": "messages",
      "type": "base",
      "schema": [
        {
          "name": "conversation_id",
          "type": "relation",
          "required": true,
          "options": {
            "collectionId": "conversations",
            "cascadeDelete": true,
            "maxSelect": 1
          }
        },
        {
          "name": "content",
          "type": "text",
          "required": true,
          "options": {"min": 1, "max": 10000}
        },
        {
          "name": "is_user",
          "type": "bool",
          "required": true
        },
        {
          "name": "token_count",
          "type": "number",
          "required": false,
          "options": {"min": 0}
        }
      ],
      "indexes": [
        "CREATE INDEX idx_messages_conversation_id ON messages (conversation_id)",
        "CREATE INDEX idx_messages_created ON messages (created)"
      ],
      "listRule": "conversation_id.user_id = @request.auth.id",
      "viewRule": "conversation_id.user_id = @request.auth.id",
      "createRule": "conversation_id.user_id = @request.auth.id",
      "updateRule": "conversation_id.user_id = @request.auth.id",
      "deleteRule": "conversation_id.user_id = @request.auth.id"
    };

    await _createCollection(authToken, schema);
  }

  Future<void> _createUsageAnalyticsCollection(String authToken) async {
    print('📝 Creating usage_analytics collection...');

    final schema = {
      "name": "usage_analytics",
      "type": "base",
      "schema": [
        {
          "name": "user_id",
          "type": "relation",
          "required": true,
          "options": {
            "collectionId": "users",
            "cascadeDelete": true,
            "maxSelect": 1
          }
        },
        {
          "name": "chatbot_id",
          "type": "text",
          "required": true,
          "options": {"min": 1, "max": 100}
        },
        {
          "name": "message_count",
          "type": "number",
          "required": true,
          "options": {"min": 0}
        },
        {
          "name": "token_usage",
          "type": "number",
          "required": true,
          "options": {"min": 0}
        },
        {
          "name": "date",
          "type": "date",
          "required": true
        }
      ],
      "indexes": [
        "CREATE INDEX idx_usage_user_id ON usage_analytics (user_id)",
        "CREATE INDEX idx_usage_date ON usage_analytics (date)"
      ],
      "listRule": "user_id = @request.auth.id",
      "viewRule": "user_id = @request.auth.id",
      "createRule": "user_id = @request.auth.id",
      "updateRule": "user_id = @request.auth.id",
      "deleteRule": "user_id = @request.auth.id"
    };

    await _createCollection(authToken, schema);
  }

  Future<void> _createCollection(String authToken, Map<String, dynamic> schema) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/collections'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(schema),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Collection "${schema['name']}" created successfully');
      } else {
        print('⚠️  Collection "${schema['name']}" might already exist or error: ${response.body}');
      }
    } catch (e) {
      print('❌ Error creating collection "${schema['name']}": $e');
    }
  }
}

// Example usage
void main() async {
  final setup = PocketBaseSetup(
    baseUrl: 'http://localhost:8090',
    adminEmail: 'admin@example.com',
    adminPassword: 'admin123',
  );

  await setup.setupCollections();
}
