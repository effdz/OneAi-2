import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:oneai/models/chatbot_model.dart';
import 'package:oneai/screens/chat_screen.dart';
import 'package:oneai/screens/conversation_history_screen.dart';
import 'package:oneai/services/chatbot_service.dart';
import 'package:oneai/utils/responsive.dart';
import 'package:oneai/utils/platform_adaptive.dart';
import 'package:provider/provider.dart';
import 'package:oneai/widgets/app_drawer.dart';
import 'package:oneai/main.dart';
import 'package:oneai/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatbots = ChatbotService.getChatbots();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isApple = PlatformAdaptive.isApplePlatform();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Platform-specific app bar
    final appBar = PlatformAdaptive.appBar(
      context: context,
      title: 'OneAI Chatbot Hub',
      actions: [
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode
                ? (isApple ? CupertinoIcons.sun_max : Icons.light_mode)
                : (isApple ? CupertinoIcons.moon : Icons.dark_mode),
          ),
          onPressed: themeProvider.toggleTheme,
          tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        ),
        IconButton(
          icon: Icon(isApple ? CupertinoIcons.settings : Icons.settings),
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
          tooltip: 'Settings',
        ),
      ],
      backgroundColor: Theme.of(context).colorScheme.surface,
    );

    return Scaffold(
      appBar: appBar,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  icon: Icon(isApple ? CupertinoIcons.chat_bubble_2 : Icons.chat_bubble_outline),
                  text: 'Chatbots',
                ),
                Tab(
                  icon: Icon(isApple ? CupertinoIcons.time : Icons.history),
                  text: 'History',
                ),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatbotsTab(chatbots),
                const ConversationHistoryScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatbotsTab(List<ChatbotModel> chatbots) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final padding = Responsive.responsivePadding(context);
    final titleSize = Responsive.responsiveFontSize(
        context,
        mobile: 24,
        tablet: 28,
        desktop: 32
    );
    final subtitleSize = Responsive.responsiveFontSize(
        context,
        mobile: 16,
        tablet: 18,
        desktop: 20
    );

    // Grid columns based on screen size
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Choose an AI Assistant',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.displaySmall?.color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select from multiple AI chatbots to start a conversation',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: chatbots.length,
                  itemBuilder: (context, index) {
                    final chatbot = chatbots[index];
                    return _ChatbotCard(chatbot: chatbot);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatbotCard extends StatelessWidget {
  final ChatbotModel chatbot;

  const _ChatbotCard({required this.chatbot});

  @override
  Widget build(BuildContext context) {
    final isApple = PlatformAdaptive.isApplePlatform();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Hero(
      tag: 'chatbot-${chatbot.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatbot: chatbot),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: chatbot.color.withOpacity(isDark ? 0.2 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: chatbot.color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: chatbot.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: chatbot.color.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isApple ? _getAppleIcon(chatbot.id) : chatbot.icon,
                        size: 40,
                        color: chatbot.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      chatbot.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.25,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      chatbot.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
