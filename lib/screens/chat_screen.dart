import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:oneai/models/chatbot_model.dart';
import 'package:oneai/models/message_model.dart';
import 'package:oneai/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:oneai/utils/responsive.dart';
import 'package:oneai/utils/platform_adaptive.dart';
import 'package:oneai/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final ChatbotModel chatbot;

  const ChatScreen({super.key, required this.chatbot});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Animation controllers
  late AnimationController _sendButtonController;
  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    // Initialize chat with selected chatbot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false)
          .initChat(widget.chatbot.id);
    });

    // Initialize animation controllers
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Listen for text changes to animate send button
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty) {
      _sendButtonController.forward();
    } else {
      _sendButtonController.reverse();
    }
  }


  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();
    _focusNode.unfocus();

    Provider.of<ChatProvider>(context, listen: false).sendMessage(message);

    // Scroll to bottom after sending message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isApple = PlatformAdaptive.isApplePlatform();
    final padding = Responsive.responsivePadding(context);
    final isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Platform-specific app bar
    final appBar = PlatformAdaptive.appBar(
      context: context,
      title: widget.chatbot.name,
      leading: IconButton(
        icon: Icon(isApple ? CupertinoIcons.back : Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(isApple ? CupertinoIcons.refresh : Icons.refresh),
          onPressed: () {
            Provider.of<ChatProvider>(context, listen: false)
                .clearChat(widget.chatbot.id);
          },
          tooltip: 'Clear Chat',
        ),
      ],
    );

    // Responsive chat container width
    final chatContainerWidth = isDesktop
        ? MediaQuery.of(context).size.width * 0.7
        : MediaQuery.of(context).size.width;

    return PlatformAdaptive.scaffold(
      context: context,
      appBar: appBar,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  final messages = chatProvider.messages;

                  if (messages.isEmpty) {
                    return _buildEmptyChatView();
                  }

                  // Auto-scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: chatContainerWidth,
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: padding,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final showAvatar = _shouldShowAvatar(messages, index);

                          return _MessageBubble(
                            message: message,
                            chatbotColor: widget.chatbot.color,
                            chatbotIcon: isApple
                                ? _getAppleIcon(widget.chatbot.id)
                                : widget.chatbot.icon,
                            showAvatar: showAvatar,
                            isFirstInSequence: _isFirstInSequence(messages, index),
                            isLastInSequence: _isLastInSequence(messages, index),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildChatInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChatView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: widget.chatbot.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: widget.chatbot.color.withOpacity(isDark ? 0.2 : 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              PlatformAdaptive.isApplePlatform()
                  ? _getAppleIcon(widget.chatbot.id)
                  : widget.chatbot.icon,
              size: 60,
              color: widget.chatbot.color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start chatting with ${widget.chatbot.name}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Ask questions, get creative ideas, or just have a conversation',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          PlatformAdaptive.button(
            text: 'Start Conversation',
            onPressed: () {
              _focusNode.requestFocus();
            },
            backgroundColor: widget.chatbot.color,
            icon: PlatformAdaptive.isApplePlatform()
                ? CupertinoIcons.chat_bubble_text
                : Icons.chat,
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final isLoading = chatProvider.isLoading;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 5,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: PlatformAdaptive.textField(
                    controller: _messageController,
                    placeholder: 'Type a message...',
                    focusNode: _focusNode,
                    onEditingComplete: _sendMessage,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _sendButtonController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: Tween<double>(begin: 1.0, end: 1.1)
                        .animate(CurvedAnimation(
                      parent: _sendButtonController,
                      curve: Curves.elasticOut,
                    ))
                        .value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.chatbot.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.chatbot.color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: isLoading
                            ? PlatformAdaptive.progressIndicator(color: Colors.white)
                            : Icon(
                          PlatformAdaptive.isApplePlatform()
                              ? CupertinoIcons.arrow_up
                              : Icons.send,
                          color: Colors.white,
                        ),
                        onPressed: isLoading ? () {} : _sendMessage,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _shouldShowAvatar(List<MessageModel> messages, int index) {
    if (index == 0) return true;
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    // Show avatar if this is the first message from this sender
    return currentMessage.isUser != previousMessage.isUser;
  }

  bool _isFirstInSequence(List<MessageModel> messages, int index) {
    if (index == 0) return true;
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    return currentMessage.isUser != previousMessage.isUser;
  }

  bool _isLastInSequence(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];

    return currentMessage.isUser != nextMessage.isUser;
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

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final Color chatbotColor;
  final IconData chatbotIcon;
  final bool showAvatar;
  final bool isFirstInSequence;
  final bool isLastInSequence;

  const _MessageBubble({
    required this.message,
    required this.chatbotColor,
    required this.chatbotIcon,
    this.showAvatar = true,
    this.isFirstInSequence = true,
    this.isLastInSequence = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isUser
        ? chatbotColor
        : (isDark ? Colors.grey[800] : Colors.grey[200]);
    final textColor = isUser
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color;

    // Bubble border radius based on position in sequence
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isUser || !isFirstInSequence ? 20 : 4),
      topRight: Radius.circular(!isUser || !isFirstInSequence ? 20 : 4),
      bottomLeft: Radius.circular(isUser || !isLastInSequence ? 20 : 4),
      bottomRight: Radius.circular(!isUser || !isLastInSequence ? 20 : 4),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLastInSequence ? 12 : 4,
        top: isFirstInSequence ? 12 : 4,
      ),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && showAvatar) ...[
            _buildAvatar(context, isUser: false),
            const SizedBox(width: 8),
          ] else if (!isUser && !showAvatar) ...[
            const SizedBox(width: 40), // Space for avatar alignment
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (isUser && showAvatar) ...[
            const SizedBox(width: 8),
            _buildAvatar(context, isUser: true),
          ] else if (isUser && !showAvatar) ...[
            const SizedBox(width: 40), // Space for avatar alignment
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, {required bool isUser}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : chatbotColor.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
            color: (isUser
                ? Theme.of(context).colorScheme.primary
                : chatbotColor).withOpacity(isDark ? 0.3 : 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isUser
              ? (PlatformAdaptive.isApplePlatform()
              ? CupertinoIcons.person
              : Icons.person)
              : chatbotIcon,
          size: 16,
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : chatbotColor,
        ),
      ),
    );
  }
}
