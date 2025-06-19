import 'package:flutter/material.dart';
import 'package:oneai/services/network_checker.dart';

class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({Key? key}) : super(key: key);

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  bool _isChecking = false;
  bool? _hasInternet;
  Map<String, bool> _apiStatus = {};

  @override
  void initState() {
    super.initState();
    _checkNetworkStatus();
  }

  Future<void> _checkNetworkStatus() async {
    setState(() {
      _isChecking = true;
    });

    try {
      _hasInternet = await NetworkChecker.hasInternetConnection();
      if (_hasInternet == true) {
        _apiStatus = await NetworkChecker.checkAllAPIs();
      }
    } catch (e) {
      print('Error checking network: $e');
    }

    setState(() {
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.network_check, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Network Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isChecking)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: _checkNetworkStatus,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Internet status
            Row(
              children: [
                Icon(
                  _hasInternet == true ? Icons.wifi : Icons.wifi_off,
                  color: _hasInternet == true ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Internet: ${_hasInternet == true ? "Connected" : "Disconnected"}',
                  style: TextStyle(
                    color: _hasInternet == true ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            if (_apiStatus.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'API Endpoints:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._apiStatus.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      entry.value ? Icons.check_circle : Icons.error,
                      color: entry.value ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.key}: ${entry.value ? "Reachable" : "Unreachable"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: entry.value ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
