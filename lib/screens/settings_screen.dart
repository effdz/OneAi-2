import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:oneai/services/api_key_service.dart';
import 'package:oneai/services/storage_manager.dart';
import 'package:oneai/screens/pocketbase_setup_screen.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
                      icon: Icon(isApple ? CupertinoIcons.cloud : Icons.cloud),
                      text: 'Storage',
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
                      _buildStorageTab(padding),
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

  Widget _buildStorageTab(EdgeInsets padding) {
    return Consumer<StorageProvider>(
      builder: (context, storageProvider, child) {
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Storage Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Configure where your chat data is stored',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Current Storage Type
              _buildStorageTypeCard(storageProvider),
              const SizedBox(height: 16),

              // PocketBase Setup
              _buildPocketBaseCard(),
              const SizedBox(height: 16),

              // Storage Options
              _buildStorageOptions(storageProvider),
              const SizedBox(height: 16),

              // Auto Sync
              _buildAutoSyncOption(storageProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStorageTypeCard(StorageProvider storageProvider) {
    String storageTypeText;
    Color statusColor;
    IconData statusIcon;

    switch (storageProvider.currentStorage) {
      case StorageType.local:
        storageTypeText = 'Local Storage';
        statusColor = Colors.blue;
        statusIcon = PlatformAdaptive.isApplePlatform() ? CupertinoIcons.device_phone_portrait : Icons.phone_android;
        break;
      case StorageType.pocketbase:
        storageTypeText = 'Cloud Storage (PocketBase)';
        statusColor = Colors.green;
        statusIcon = PlatformAdaptive.isApplePlatform() ? CupertinoIcons.cloud : Icons.cloud;
        break;
      case StorageType.hybrid:
        storageTypeText = 'Hybrid Storage';
        statusColor = Colors.purple;
        statusIcon = PlatformAdaptive.isApplePlatform() ? CupertinoIcons.arrow_2_circlepath : Icons.sync;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                const Text(
                  'Current Storage',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              storageTypeText,
              style: TextStyle(
                fontSize: 16,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (storageProvider.storageStatus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Status: ${storageProvider.storageStatus['current_storage']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPocketBaseCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PlatformAdaptive.isApplePlatform() ? CupertinoIcons.cloud : Icons.cloud,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'PocketBase Setup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure cloud storage with PocketBase for data synchronization across devices.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PocketBaseSetupScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Configure PocketBase'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageOptions(StorageProvider storageProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Storage Options',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStorageOption(
              'Local Storage',
              'Store data only on this device',
              StorageType.local,
              storageProvider,
              Icons.phone_android,
            ),
            const SizedBox(height: 8),
            _buildStorageOption(
              'Cloud Storage',
              'Store data in PocketBase cloud',
              StorageType.pocketbase,
              storageProvider,
              Icons.cloud,
            ),
            const SizedBox(height: 8),
            _buildStorageOption(
              'Hybrid Storage',
              'Use both local and cloud storage',
              StorageType.hybrid,
              storageProvider,
              Icons.sync,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageOption(
      String title,
      String subtitle,
      StorageType storageType,
      StorageProvider storageProvider,
      IconData icon,
      ) {
    final isSelected = storageProvider.currentStorage == storageType;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primaryColor : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
        PlatformAdaptive.isApplePlatform() ? CupertinoIcons.checkmark : Icons.check,
        color: AppTheme.primaryColor,
      )
          : null,
      onTap: () async {
        if (!isSelected) {
          final success = await storageProvider.switchStorage(storageType);
          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to switch to $title'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildAutoSyncOption(StorageProvider storageProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              PlatformAdaptive.isApplePlatform() ? CupertinoIcons.arrow_2_circlepath : Icons.sync,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Auto Sync',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Automatically sync data between local and cloud storage',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            PlatformAdaptive.switchWidget(
              value: storageProvider.autoSync,
              onChanged: (value) {
                storageProvider.setAutoSync(value);
              },
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
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
              'A mobile application that integrates multiple AI chatbot providers into a single, user-friendly interface with hybrid storage capabilities.',
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
