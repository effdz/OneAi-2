import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:oneai/services/pocketbase_service.dart';
import 'package:oneai/services/storage_manager.dart';
import 'package:oneai/utils/platform_adaptive.dart';
import 'package:oneai/utils/responsive.dart';
import 'package:oneai/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:oneai/main.dart';

class PocketBaseSetupScreen extends StatefulWidget {
  const PocketBaseSetupScreen({Key? key}) : super(key: key);

  @override
  State<PocketBaseSetupScreen> createState() => _PocketBaseSetupScreenState();
}

class _PocketBaseSetupScreenState extends State<PocketBaseSetupScreen> {
  final TextEditingController _urlController = TextEditingController();
  final PocketBaseService _pbService = PocketBaseService();

  bool _isLoading = false;
  bool _isConnected = false;
  bool _collectionsExist = false;
  String _statusMessage = '';
  Map<String, dynamic>? _serverInfo;

  @override
  void initState() {
    super.initState();
    _urlController.text = _pbService.baseUrl;
    _checkCurrentStatus();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking current status...';
    });

    try {
      _isConnected = await _pbService.checkConnection();
      if (_isConnected) {
        _collectionsExist = await _pbService.checkCollectionsExist();
        _serverInfo = await _pbService.getServerInfo();
        _statusMessage = _collectionsExist
            ? 'PocketBase is ready to use!'
            : 'Connected but collections are missing';
      } else {
        _statusMessage = 'Cannot connect to PocketBase server';
      }
    } catch (e) {
      _statusMessage = 'Error: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing connection...';
    });

    try {
      final success = await _pbService.updateBaseUrl(_urlController.text.trim());
      if (success) {
        _isConnected = true;
        _collectionsExist = await _pbService.checkCollectionsExist();
        _serverInfo = await _pbService.getServerInfo();
        _statusMessage = _collectionsExist
            ? 'Connection successful! PocketBase is ready.'
            : 'Connected but collections need to be created';
      } else {
        _isConnected = false;
        _collectionsExist = false;
        _statusMessage = 'Failed to connect to PocketBase server';
      }
    } catch (e) {
      _isConnected = false;
      _collectionsExist = false;
      _statusMessage = 'Connection error: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _switchToCloudStorage() async {
    if (!_isConnected || !_collectionsExist) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PocketBase must be connected and configured first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Switching to cloud storage...';
    });

    try {
      final storageProvider = Provider.of<StorageProvider>(context, listen: false);
      final success = await storageProvider.switchStorage(StorageType.pocketbase);

      if (success) {
        _statusMessage = 'Successfully switched to cloud storage!';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Switched to cloud storage successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _statusMessage = 'Failed to switch to cloud storage';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to switch to cloud storage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _statusMessage = 'Error switching storage: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _switchToHybridStorage() async {
    if (!_isConnected || !_collectionsExist) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PocketBase must be connected and configured first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Switching to hybrid storage...';
    });

    try {
      final storageProvider = Provider.of<StorageProvider>(context, listen: false);
      final success = await storageProvider.switchStorage(StorageType.hybrid);

      if (success) {
        _statusMessage = 'Successfully switched to hybrid storage!';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Switched to hybrid storage successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _statusMessage = 'Failed to switch to hybrid storage';
      }
    } catch (e) {
      _statusMessage = 'Error switching storage: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isApple = PlatformAdaptive.isApplePlatform();
    final padding = Responsive.responsivePadding(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: PlatformAdaptive.appBar(
        context: context,
        title: 'PocketBase Setup',
        leading: IconButton(
          icon: Icon(isApple ? CupertinoIcons.back : Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: padding,
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Header
                  Text(
                    'Configure PocketBase',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up cloud storage for your chat data using PocketBase',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // URL Input
                  _buildUrlInput(),
                  const SizedBox(height: 24),

                  // Status Card
                  _buildStatusCard(),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),
                  const SizedBox(height: 24),

                  // Server Info
                  if (_serverInfo != null) _buildServerInfo(),
                  const SizedBox(height: 24),

                  // Instructions
                  _buildInstructions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrlInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PocketBase URL',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        PlatformAdaptive.textField(
          controller: _urlController,
          placeholder: 'http://localhost:8090',
          decoration: InputDecoration(
            hintText: 'Enter PocketBase server URL',
            prefixIcon: Icon(
              PlatformAdaptive.isApplePlatform() ? CupertinoIcons.link : Icons.link,
              color: AppTheme.primaryColor,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                PlatformAdaptive.isApplePlatform() ? CupertinoIcons.checkmark : Icons.check,
              ),
              onPressed: _isLoading ? null : _testConnection,
              tooltip: 'Test Connection',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;

    if (_isLoading) {
      statusColor = Colors.blue;
      statusIcon = PlatformAdaptive.isApplePlatform() ? CupertinoIcons.clock : Icons.access_time;
    } else if (_isConnected && _collectionsExist) {
      statusColor = Colors.green;
      statusIcon = PlatformAdaptive.isApplePlatform() ? CupertinoIcons.checkmark_circle : Icons.check_circle;
    } else if (_isConnected) {
      statusColor = Colors.orange;
      statusIcon = PlatformAdaptive.isApplePlatform() ? CupertinoIcons.exclamationmark_triangle : Icons.warning;
    } else {
      statusColor = Colors.red;
      statusIcon = PlatformAdaptive.isApplePlatform() ? CupertinoIcons.xmark_circle : Icons.error;
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
                  'Connection Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: PlatformAdaptive.progressIndicator(color: statusColor),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              style: TextStyle(color: statusColor),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusIndicator('Connected', _isConnected),
                const SizedBox(width: 16),
                _buildStatusIndicator('Collections', _collectionsExist),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive
              ? (PlatformAdaptive.isApplePlatform() ? CupertinoIcons.checkmark : Icons.check)
              : (PlatformAdaptive.isApplePlatform() ? CupertinoIcons.xmark : Icons.close),
          size: 16,
          color: isActive ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _testConnection,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: PlatformAdaptive.progressIndicator(color: Colors.white),
            )
                : const Text('Test Connection'),
          ),
        ),
        const SizedBox(height: 12),
        if (_isConnected && _collectionsExist) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _switchToCloudStorage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Switch to Cloud Storage'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _switchToHybridStorage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Switch to Hybrid Storage'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Server Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('URL', _serverInfo!['url']),
            _buildInfoRow('Status', _serverInfo!['status']),
            _buildInfoRow('Authenticated', _serverInfo!['authenticated'].toString()),
            if (_serverInfo!['user_id'] != null)
              _buildInfoRow('User ID', _serverInfo!['user_id']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PlatformAdaptive.isApplePlatform() ? CupertinoIcons.info : Icons.info_outline,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Setup Instructions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Download PocketBase from pocketbase.io\n'
                  '2. Run: ./pocketbase serve\n'
                  '3. Open admin panel at http://localhost:8090/_/\n'
                  '4. Create admin account\n'
                  '5. Import collections from the app\n'
                  '6. Test connection above',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
