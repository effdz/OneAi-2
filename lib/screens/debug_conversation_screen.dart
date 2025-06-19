import 'package:flutter/material.dart';
import 'package:oneai/services/database_service.dart';
import 'package:oneai/services/pocketbase_service.dart';
import 'package:oneai/services/auth_service.dart';
import 'package:oneai/services/storage_manager.dart';
import 'package:oneai/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugConversationScreen extends StatefulWidget {
  const DebugConversationScreen({Key? key}) : super(key: key);

  @override
  State<DebugConversationScreen> createState() => _DebugConversationScreenState();
}

class _DebugConversationScreenState extends State<DebugConversationScreen> {
  final DatabaseService _dbService = DatabaseService();
  final PocketBaseService _pbService = PocketBaseService();
  final StorageManager _storageManager = StorageManager();

  Map<String, dynamic> debugInfo = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      final info = <String, dynamic>{};

      // 1. Check current user
      final userId = await AuthService.getUserId();
      info['current_user_id'] = userId;
      info['user_logged_in'] = userId != null;

      // 2. Check storage type
      info['storage_type'] = _storageManager.currentStorage.toString();

      // 3. Check SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      info['shared_prefs_keys'] = allKeys.toList();

      // Get specific data
      info['stored_user_id'] = prefs.getString('user_id');
      info['stored_username'] = prefs.getString('username');
      info['stored_email'] = prefs.getString('email');

      // 4. Check raw conversations data
      final conversationsJson = prefs.getStringList('conversations') ?? [];
      info['raw_conversations_count'] = conversationsJson.length;
      info['raw_conversations'] = conversationsJson;

      // 5. Check raw messages data
      final messagesJson = prefs.getStringList('messages') ?? [];
      info['raw_messages_count'] = messagesJson.length;
      info['raw_messages'] = messagesJson;

      // 6. Check raw users data
      final usersJson = prefs.getStringList('users') ?? [];
      info['raw_users_count'] = usersJson.length;
      info['raw_users'] = usersJson;

      if (userId != null) {
        // 7. Try to get conversations using DatabaseService
        try {
          final conversations = await _dbService.getUserConversations(userId);
          info['db_service_conversations_count'] = conversations.length;
          info['db_service_conversations'] = conversations.map((c) => {
            'id': c.id,
            'title': c.title,
            'user_id': c.userId,
            'chatbot_id': c.chatbotId,
            'message_count': c.messageCount,
            'created_at': c.createdAt.toString(),
            'updated_at': c.updatedAt.toString(),
          }).toList();
        } catch (e) {
          info['db_service_error'] = e.toString();
        }

        // 8. Check if PocketBase is available
        if (_storageManager.currentStorage == StorageType.pocketbase) {
          try {
            await _pbService.initialize();
            final pbConversations = await _pbService.getUserConversations(userId);
            info['pocketbase_conversations_count'] = pbConversations.length;
            info['pocketbase_conversations'] = pbConversations.map((c) => {
              'id': c.id,
              'title': c.title,
              'user_id': c.userId,
              'chatbot_id': c.chatbotId,
              'message_count': c.messageCount,
            }).toList();
          } catch (e) {
            info['pocketbase_error'] = e.toString();
          }
        }

        // 9. Check ChatProvider state
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        info['chat_provider_conversations_count'] = chatProvider.conversations.length;
        info['chat_provider_loading'] = chatProvider.isLoadingConversations;
      }

      setState(() {
        debugInfo = info;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        debugInfo = {'error': e.toString()};
        isLoading = false;
      });
    }
  }

  Future<void> _createTestConversation() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user logged in')),
        );
        return;
      }

      final conversationId = await _dbService.createConversation(
          userId,
          'openai',
          'Test Conversation ${DateTime.now().millisecondsSinceEpoch}'
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created test conversation: $conversationId')),
      );

      await _loadDebugInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating conversation: $e')),
      );
    }
  }

  Future<void> _clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('conversations');
      await prefs.remove('messages');
      await prefs.remove('users');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared')),
      );

      await _loadDebugInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createTestConversation,
                    child: const Text('Create Test Conversation'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearAllData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear All Data'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Debug Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...debugInfo.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatValue(entry.value),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value is List) {
      if (value.isEmpty) return '[]';
      return value.map((item) => item.toString()).join('\n');
    } else if (value is Map) {
      if (value.isEmpty) return '{}';
      return value.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n');
    }
    return value.toString();
  }
}
