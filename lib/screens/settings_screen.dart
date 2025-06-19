import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:oneai/services/api_key_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oneai/utils/responsive.dart';
import 'package:oneai/utils/platform_adaptive.dart';
import 'package:oneai/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:oneai/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _openaiController = TextEditingController();
  final TextEditingController _geminiController = TextEditingController();
  final TextEditingController _huggingfaceController = TextEditingController();
  final TextEditingController _mistralController = TextEditingController();
  final TextEditingController _deepinfraController = TextEditingController();
  final TextEditingController _openrouterController = TextEditingController();
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadApiKeys();
  }

  Future<void> _loadApiKeys() async {
    setState(() {
      _isLoading = true;
    });

    final keys = await ApiKeyService.loadAllApiKeys();

    setState(() {
      _openaiController.text = keys[ApiKeyService.openaiKey] ?? '';
      _geminiController.text = keys[ApiKeyService.geminiKey] ?? '';
      _huggingfaceController.text = keys[ApiKeyService.huggingfaceKey] ?? '';
      _mistralController.text = keys[ApiKeyService.mistralKey] ?? '';
      _deepinfraController.text = keys[ApiKeyService.deepinfraKey] ?? '';
      _openrouterController.text = keys[ApiKeyService.openrouterKey] ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveApiKey(String key, String value) async {
    setState(() {
      _isLoading = true;
    });

    await ApiKeyService.saveApiKey(key, value);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API key saved'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _openaiController.dispose();
    _geminiController.dispose();
    _huggingfaceController.dispose();
    _mistralController.dispose();
    _deepinfraController.dispose();
    _openrouterController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isApple = PlatformAdaptive.isApplePlatform();
    final padding = Responsive.responsivePadding(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDesktop = Responsive.isDesktop(context);

    // Platform-specific app bar
    final appBar = PlatformAdaptive.appBar(
      context: context,
      title: 'Settings',
      leading: IconButton(
        icon: Icon(isApple ? CupertinoIcons.back : Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );

    // Responsive container width
    final containerWidth = isDesktop
        ? MediaQuery.of(context).size.width * 0.6
        : MediaQuery.of(context).size.width;

    return PlatformAdaptive.scaffold(
      context: context,
      appBar: appBar,
      body: _isLoading
          ? Center(child: PlatformAdaptive.progressIndicator(color: AppTheme.primaryColor))
          : SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: containerWidth,
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      icon: Icon(isApple ? CupertinoIcons.lock : Icons.key),
                      text: 'API Keys',
                    ),
                    Tab(
                      icon: Icon(isApple ? CupertinoIcons.settings : Icons.settings),
                      text: 'Preferences',
                    ),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildApiKeysTab(padding),
                      _buildPreferencesTab(padding, themeProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeysTab(EdgeInsets padding) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'API Keys',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your API keys to use the respective AI services',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          _buildApiKeyField(
            'OpenAI API Key',
            'Enter your OpenAI API key',
            _openaiController,
            ApiKeyService.openaiKey,
            AppTheme.openaiColor,
          ),
          const SizedBox(height: 16),
          _buildApiKeyField(
            'Google AI API Key (Gemini)',
            'Enter your Google AI API key',
            _geminiController,
            ApiKeyService.geminiKey,
            const Color(0xFF4285F4),
          ),
          const SizedBox(height: 16),
          _buildApiKeyField(
            'Mistral AI API Key',
            'Enter your Mistral AI API key',
            _mistralController,
            ApiKeyService.mistralKey,
            const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 16),
          _buildApiKeyField(
            'DeepInfra API Key',
            'Enter your DeepInfra API key',
            _deepinfraController,
            ApiKeyService.deepinfraKey,
            const Color(0xFFFF6B6B),
          ),
          const SizedBox(height: 16),
          _buildApiKeyField(
            'OpenRouter API Key',
            'Enter your OpenRouter API key',
            _openrouterController,
            ApiKeyService.openrouterKey,
            const Color(0xFF00A3E1),
          ),
          const SizedBox(height: 16),
          _buildApiKeyField(
            'Hugging Face API Key',
            'Enter your Hugging Face API key',
            _huggingfaceController,
            ApiKeyService.huggingfaceKey,
            AppTheme.huggingfaceColor,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  PlatformAdaptive.isApplePlatform()
                      ? CupertinoIcons.info
                      : Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your API keys are stored securely on your device and are not shared with anyone.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab(EdgeInsets padding, ThemeProvider themeProvider) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildPreferenceItem(
            title: 'Dark Mode',
            subtitle: 'Use dark theme for the application',
            trailing: PlatformAdaptive.switchWidget(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          _buildPreferenceItem(
            title: 'Storage Settings',
            subtitle: 'Configure local and cloud storage options',
            trailing: Icon(
              PlatformAdaptive.isApplePlatform()
                  ? CupertinoIcons.chevron_right
                  : Icons.chevron_right,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            onTap: () {
              Navigator.pushNamed(context, '/storage-settings');
            },
          ),
          const Divider(),
          _buildPreferenceItem(
            title: 'About',
            subtitle: 'OneAI Chatbot Hub v1.0.0',
            trailing: Icon(
              PlatformAdaptive.isApplePlatform()
                  ? CupertinoIcons.chevron_right
                  : Icons.chevron_right,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            onTap: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyField(
      String label,
      String hint,
      TextEditingController controller,
      String prefKey,
      Color color,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        PlatformAdaptive.textField(
          controller: controller,
          placeholder: hint,
          obscureText: true,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: color.withOpacity(0.1),
            prefixIcon: Icon(
              PlatformAdaptive.isApplePlatform()
                  ? CupertinoIcons.lock
                  : Icons.key,
              color: color,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                PlatformAdaptive.isApplePlatform()
                    ? CupertinoIcons.floppy_disk
                    : Icons.save,
              ),
              onPressed: () => _saveApiKey(prefKey, controller.text),
              tooltip: 'Save API Key',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem({
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About OneAI'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OneAI Chatbot Hub',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A mobile application that integrates multiple AI chatbot providers into a single, user-friendly interface.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
