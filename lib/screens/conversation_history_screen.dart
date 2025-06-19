import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:oneai/models/conversation_model.dart';
import 'package:oneai/providers/chat_provider.dart';
import 'package:oneai/screens/chat_screen.dart';
import 'package:oneai/services/chatbot_service.dart';
import 'package:oneai/utils/platform_adaptive.dart';
import 'package:oneai/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ConversationHistoryScreen extends StatefulWidget {
  const ConversationHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ConversationHistoryScreen> createState() => _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState extends State<ConversationHistoryScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isApple = PlatformAdaptive.isApplePlatform();
    final padding = Responsive.responsivePadding(context);

    return Scaffold(
      appBar: _buildAppBar(isApple),
      body: SafeArea(
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            if (chatProvider.isLoadingConversations) {
              return const Center(child: CircularProgressIndicator());
            }

            final conversations = chatProvider.conversations;

            if (conversations.isEmpty) {
              return _buildEmptyState();
            }

            // Filter conversations if searching
            final filteredConversations = _searchQuery.isEmpty
                ? conversations
                : conversations.where((conv) =>
                conv.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

            if (filteredConversations.isEmpty) {
              return _buildNoResultsFound();
            }

            return ListView.builder(
              padding: padding,
              itemCount: filteredConversations.length,
              itemBuilder: (context, index) {
                final conversation = filteredConversations[index];
                return _buildConversationItem(conversation);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewChatDialog();
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          isApple ? CupertinoIcons.chat_bubble_text : Icons.chat,
          color: Colors.white,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isApple) {
    if (_isSearching) {
      return AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _onSearchChanged,
        ),
        leading: IconButton(
          icon: Icon(isApple ? CupertinoIcons.back : Icons.arrow_back),
          onPressed: _stopSearch,
        ),
      );
    } else {
      return AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(
            icon: Icon(isApple ? CupertinoIcons.search : Icons.search),
            onPressed: _startSearch,
            tooltip: 'Search',
          ),
        ],
      );
    }
  }

  Widget _buildEmptyState() {
    final isApple = PlatformAdaptive.isApplePlatform();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isApple ? CupertinoIcons.chat_bubble_2 : Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new chat to begin',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showNewChatDialog();
            },
            icon: Icon(isApple ? CupertinoIcons.add : Icons.add),
            label: const Text('New Chat'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound() {
    final isApple = PlatformAdaptive.isApplePlatform();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isApple ? CupertinoIcons.search : Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(ConversationModel conversation) {
    final isApple = PlatformAdaptive.isApplePlatform();
    final chatbot = ChatbotService.getChatbots().firstWhere(
          (bot) => bot.id == conversation.chatbotId,
      orElse: () => ChatbotService.getChatbots().first,
    );

    final formattedDate = _formatDate(conversation.updatedAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: chatbot.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: chatbot.color.withOpacity(0.2),
          child: Icon(
            isApple ? _getAppleIcon(chatbot.id) : chatbot.icon,
            color: chatbot.color,
          ),
        ),
        title: Text(
          conversation.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${chatbot.name} • ${conversation.messageCount} messages',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formattedDate,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            isApple ? CupertinoIcons.ellipsis_vertical : Icons.more_vert,
            color: Colors.grey.shade600,
          ),
          onPressed: () {
            _showConversationOptions(conversation);
          },
        ),
        onTap: () {
          _openConversation(conversation);
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE, HH:mm').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  void _showConversationOptions(ConversationModel conversation) {
    final isApple = PlatformAdaptive.isApplePlatform();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isApple ? CupertinoIcons.pencil : Icons.edit,
                  color: Colors.blue,
                ),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(conversation);
                },
              ),
              ListTile(
                leading: Icon(
                  isApple ? CupertinoIcons.archivebox : Icons.archive,
                  color: Colors.amber,
                ),
                title: const Text('Archive'),
                onTap: () {
                  Navigator.pop(context);
                  _archiveConversation(conversation);
                },
              ),
              ListTile(
                leading: Icon(
                  isApple ? CupertinoIcons.delete : Icons.delete,
                  color: Colors.red,
                ),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(conversation);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(ConversationModel conversation) {
    final TextEditingController titleController = TextEditingController(text: conversation.title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Conversation'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Provider.of<ChatProvider>(context, listen: false)
                      .updateConversationTitle(conversation.id, titleController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) => titleController.dispose());
  }

  void _archiveConversation(ConversationModel conversation) {
    Provider.of<ChatProvider>(context, listen: false)
        .archiveConversation(conversation.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Conversation archived'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Implement undo functionality if needed
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ConversationModel conversation) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Conversation'),
          content: const Text(
            'Are you sure you want to delete this conversation? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<ChatProvider>(context, listen: false)
                    .deleteConversation(conversation.id);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _openConversation(ConversationModel conversation) {
    final chatbot = ChatbotService.getChatbots().firstWhere(
          (bot) => bot.id == conversation.chatbotId,
      orElse: () => ChatbotService.getChatbots().first,
    );

    Provider.of<ChatProvider>(context, listen: false)
        .loadConversation(conversation.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatbot: chatbot),
      ),
    );
  }

  void _showNewChatDialog() {
    final chatbots = ChatbotService.getChatbots();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Choose a Chatbot',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: chatbots.length,
                    itemBuilder: (context, index) {
                      final chatbot = chatbots[index];
                      final isApple = PlatformAdaptive.isApplePlatform();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: chatbot.color.withOpacity(0.2),
                          child: Icon(
                            isApple ? _getAppleIcon(chatbot.id) : chatbot.icon,
                            color: chatbot.color,
                          ),
                        ),
                        title: Text(chatbot.name),
                        subtitle: Text(chatbot.description),
                        onTap: () {
                          Navigator.pop(context);
                          _startNewChat(chatbot);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startNewChat(chatbot) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.startNewChat(chatbot.id).then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatbot: chatbot),
        ),
      );
    });
  }

  IconData _getAppleIcon(String chatbotId) {
    switch (chatbotId) {
      case 'openai':
        return CupertinoIcons.sparkles;
      case 'gemini':
        return CupertinoIcons.globe;
      case 'huggingface':
        return CupertinoIcons.square_stack_3d_down_right;
      case 'mistral':
        return CupertinoIcons.wind;
      case 'deepinfra-llama':
        return CupertinoIcons.memories;
      case 'openrouter-claude':
      case 'openrouter-mixtral':
        return CupertinoIcons.arrow_branch;
      default:
        return CupertinoIcons.chat_bubble_2;
    }
  }
}
