import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:oneai/services/storage_manager.dart';
import 'package:oneai/services/pocketbase_service.dart';
import 'package:oneai/utils/platform_adaptive.dart';
import 'package:oneai/utils/responsive.dart';
import 'package:oneai/theme/app_theme.dart';

class StorageSettingsScreen extends StatefulWidget {
  const StorageSettingsScreen({Key? key}) : super(key: key);

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  final StorageManager _storageManager = StorageManager();
  final PocketBaseService _pbService = PocketBaseService();
  final TextEditingController _urlController = TextEditingController();

  Map<String, dynamic> _storageStatus = {};
  bool _isLoading = true;
  bool _isTesting = false;
  bool _isMigrating = false;

  @override
  void initState() {
    super.initState();
    _loadStorageStatus();
    _urlController.text = _pbService.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadStorageStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await _storageManager.getStorageStatus();
      setState(() {
        _storageStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error loading storage status: $e');
    }
  }

  Future<void> _testPocketBaseConnection() async {
    setState(() {
      _isTesting = true;
    });

    try {
      final success = await _pbService.updateBaseUrl(_urlController.text.trim());

      if (success) {
        _showSuccess('PocketBase connection successful!');
        await _loadStorageStatus();
      } else {
        _showError('Failed to connect to PocketBase. Please check the URL and ensure the server is running.');
      }
    } catch (e) {
      _showError('Connection test failed: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _switchStorage(StorageType newType) async {
    try {
      final success = await _storageManager.switchStorage(newType);

      if (success) {
        _showSuccess('Storage switched to ${newType.toString().split('.').last}');
        await _loadStorageStatus();
      } else {
        _showError('Failed to switch storage. Please ensure PocketBase is available.');
      }
    } catch (e) {
      _showError('Error switching storage: $e');
    }
  }

  Future<void> _migrateToCloud() async {
    final confirm = await _showConfirmDialog(
      'Migrate to Cloud',
      'This will upload all your local data to PocketBase. Continue?',
    );

    if (!confirm) return;

    setState(() {
      _isMigrating = true;
    });

    try {
      final success = await _storageManager.migrateToCloud();

      if (success) {
        _showSuccess('Migration completed successfully!');
        await _loadStorageStatus();
      } else {
        _showError('Migration failed. Please check your PocketBase setup.');
      }
    } catch (e) {
      _showError('Migration error: $e');
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _syncData() async {
    try {
      final success = await _storageManager.syncData();

      if (success) {
        _showSuccess('Data synchronized successfully!');
        await _loadStorageStatus();
      } else {
        _showError('Sync failed or not available for current storage type.');
      }
    } catch (e) {
      _showError('Sync error: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isApple = PlatformAdaptive.isApplePlatform();
    final padding = Responsive.responsivePadding(context);

    return Scaffold(
      appBar: PlatformAdaptive.appBar(
        context: context,
        title: 'Storage Settings',
        automaticallyImplyLeading: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentStorageCard(),
            const SizedBox(height: 16),
            _buildPocketBaseConfigCard(),
            const SizedBox(height: 16),
            _buildStorageOptionsCard(),
            const SizedBox(height: 16),
            _buildActionsCard(),
            const SizedBox(height: 16),
            _buildStorageStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStorageCard() {
    final currentStorage = _storageStatus['current_storage'] ?? 'local';
    final autoSync = _storageStatus['auto_sync'] ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PlatformAdaptive.isApplePlatform()
                      ? CupertinoIcons.cloud
                      : Icons.storage,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Current Storage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentStorage.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (autoSync)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'AUTO SYNC',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Auto Sync'),
                const Spacer(),
                PlatformAdaptive.switchWidget(
                  value: autoSync,
                  onChanged: (value) {
                    _storageManager.setAutoSync(value);
                    _loadStorageStatus();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPocketBaseConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PlatformAdaptive.isApplePlatform()
                      ? CupertinoIcons.settings
                      : Icons.settings,
                  color: AppTheme.secondaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'PocketBase Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'PocketBase URL',
                hintText: 'http://localhost:8090',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isTesting ? null : _testPocketBaseConnection,
                child: _isTesting
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Testing...'),
                  ],
                )
                    : const Text('Test Connection'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageOptionsCard() {
    final currentStorage = _storageStatus['current_storage'] ?? 'local';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PlatformAdaptive.isApplePlatform()
                      ? CupertinoIcons.square_stack_3d_down_right
                      : Icons.layers,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Storage Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStorageOption(
              'Local Storage',
              'Store data locally on your device',
              StorageType.local,
              currentStorage == 'local',
              Icons.phone_android,
            ),
            _buildStorageOption(
              'Cloud Storage (PocketBase)',
              'Store data in PocketBase cloud',
              StorageType.pocketbase,
              currentStorage == 'pocketbase',
              Icons.cloud,
            ),
            _buildStorageOption(
              'Hybrid Storage',
              'Use both local and cloud storage with sync',
              StorageType.hybrid,
              currentStorage == 'hybrid',
              Icons.sync,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageOption(
      String title,
      String description,
      StorageType type,
      bool isSelected,
      IconData icon,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primaryColor : null,
          ),
        ),
        subtitle: Text(description),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
            : null,
        onTap: isSelected ? null : () => _switchStorage(type),
      ),
    );
  }

  Widget _buildActionsCard() {
    final pbAvailable = _storageStatus['pocketbase']?['available'] ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PlatformAdaptive.isApplePlatform()
                      ? CupertinoIcons.arrow_up_arrow_down
                      : Icons.sync_alt,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Data Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: pbAvailable && !_isMigrating ? _migrateToCloud : null,
                icon: _isMigrating
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isMigrating ? 'Migrating...' : 'Migrate to Cloud'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: pbAvailable ? _syncData : null,
                icon: const Icon(Icons.sync),
                label: const Text('Sync Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.infoColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageStatusCard() {
    final local = _storageStatus['local'] ?? {};
    final pocketbase = _storageStatus['pocketbase'] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PlatformAdaptive.isApplePlatform()
                      ? CupertinoIcons.info
                      : Icons.info_outline,
                  color: AppTheme.infoColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Storage Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusSection('Local Storage', local),
            const Divider(),
            _buildStatusSection('PocketBase', pocketbase),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(String title, Map<String, dynamic> status) {
    final isAvailable = status['available'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isAvailable ? Icons.check_circle : Icons.error,
              color: isAvailable ? AppTheme.successColor : AppTheme.errorColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isAvailable) ...[
          if (status.containsKey('users_count'))
            Text('Users: ${status['users_count']}'),
          if (status.containsKey('conversations_count'))
            Text('Conversations: ${status['conversations_count']}'),
          if (status.containsKey('messages_count'))
            Text('Messages: ${status['messages_count']}'),
          if (status.containsKey('url'))
            Text('URL: ${status['url']}'),
          if (status.containsKey('connected'))
            Text('Connected: ${status['connected']}'),
          if (status.containsKey('collections_exist'))
            Text('Collections: ${status['collections_exist']}'),
        ] else ...[
          Text(
            'Error: ${status['error'] ?? 'Unknown error'}',
            style: TextStyle(color: AppTheme.errorColor),
          ),
        ],
      ],
    );
  }
}
