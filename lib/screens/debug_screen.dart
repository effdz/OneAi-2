import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:oneai/services/database_service.dart';
import 'package:oneai/services/auth_service.dart';
import 'package:oneai/services/pocketbase_service.dart';
import 'package:oneai/services/pocketbase_verification.dart';
import 'package:oneai/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugInfo = 'Loading...';
  final DatabaseService _dbService = DatabaseService();
  final PocketBaseService _pbService = PocketBaseService();

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      final StringBuffer info = StringBuffer();

      // Platform info
      info.writeln('=== PLATFORM INFO ===');
      info.writeln('🌐 Platform: ${kIsWeb ? "Web" : "Mobile"}');
      info.writeln('🐛 Debug mode: ${kDebugMode}');
      info.writeln('📱 Release mode: ${kReleaseMode}');

      // Database status
      info.writeln('\n=== DATABASE STATUS ===');
      try {
        await _dbService.database;
        info.writeln('✅ Database initialized: SharedPreferences (Local)');
        info.writeln('ℹ️  PocketBase temporarily disabled');
      } catch (e) {
        info.writeln('❌ Database error: $e');
      }

      info.writeln('\n=== AUTH STATUS ===');
      try {
        final token = await AuthService.getToken();
        final userId = await AuthService.getUserId();
        final isLoggedIn = await AuthService.isLoggedIn();

        info.writeln('🔑 Token exists: ${token != null}');
        info.writeln('🆔 User ID: $userId');
        info.writeln('✅ Is logged in: $isLoggedIn');

        if (userId != null) {
          final user = await AuthService.getUser();
          info.writeln('👤 User found: ${user?.username} (${user?.email})');
        }
      } catch (e) {
        info.writeln('❌ Auth error: $e');
      }

      info.writeln('\n=== PROVIDER STATUS ===');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      info.writeln('🔄 Provider loading: ${authProvider.isLoading}');
      info.writeln('✅ Provider authenticated: ${authProvider.isAuthenticated}');
      info.writeln('👤 Provider user: ${authProvider.user?.username}');
      info.writeln('❌ Provider error: ${authProvider.error}');

      // Storage info
      info.writeln('\n=== STORAGE INFO ===');
      try {
        final prefs = await SharedPreferences.getInstance();
        final users = prefs.getStringList('users') ?? [];
        final conversations = prefs.getStringList('conversations') ?? [];
        final messages = prefs.getStringList('messages') ?? [];

        info.writeln('👥 Total users: ${users.length}');
        info.writeln('💬 Total conversations: ${conversations.length}');
        info.writeln('📝 Total messages: ${messages.length}');
      } catch (e) {
        info.writeln('❌ Storage error: $e');
      }

      setState(() {
        _debugInfo = info.toString();
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Error loading debug info: $e';
      });
    }
  }

  Future<void> _testConnection() async {
    try {
      setState(() {
        _debugInfo = 'Testing database connection...';
      });

      await _dbService.database;

      setState(() {
        _debugInfo = '''
Database Connection Test:
Type: SharedPreferences (Local Storage)
Status: ✅ SUCCESS
Ready for testing: ✅ YES

Note: PocketBase is temporarily disabled.
Using local storage for development.
        ''';
      });

      await Future.delayed(const Duration(seconds: 2));
      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _debugInfo = 'Database connection test error: $e';
      });
    }
  }

  Future<void> _verifyCollections() async {
    try {
      setState(() {
        _debugInfo = 'Verifying local storage collections...';
      });

      final isValid = await PocketBaseVerification.verifyCollections();

      setState(() {
        _debugInfo = '''
Collections Verification:
${isValid ? "✅ Local storage is working properly" : "❌ Local storage has issues"}

Storage Type: SharedPreferences
Status: ${isValid ? "Ready for use" : "Needs attention"}
        ''';
      });

      await Future.delayed(const Duration(seconds: 2));
      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _debugInfo = 'Collections verification error: $e';
      });
    }
  }

  Future<void> _testBasicOperations() async {
    try {
      setState(() {
        _debugInfo = 'Testing basic operations...';
      });

      await PocketBaseVerification.testBasicOperations();

      setState(() {
        _debugInfo = 'Basic operations test completed! Check console for details.';
      });

      await Future.delayed(const Duration(seconds: 2));
      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _debugInfo = 'Basic operations test error: $e';
      });
    }
  }

  Future<void> _createTestUser() async {
    try {
      setState(() {
        _debugInfo = 'Creating test user...';
      });

      final success = await _dbService.registerUser(
          'testuser',
          'test@example.com',
          'password123'
      );

      if (success) {
        setState(() {
          _debugInfo = 'Test user created successfully!\nEmail: test@example.com\nPassword: password123';
        });
      } else {
        setState(() {
          _debugInfo = 'Failed to create test user (might already exist)';
        });
      }

      await Future.delayed(const Duration(seconds: 2));
      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _debugInfo = 'Create test user error: $e';
      });
    }
  }

  Future<void> _testLogin() async {
    try {
      setState(() {
        _debugInfo = 'Testing login with test@example.com...';
      });

      final user = await _dbService.loginUser('test@example.com', 'password123');

      if (user != null) {
        setState(() {
          _debugInfo = 'Login test successful!\nUser: ${user.username}\nEmail: ${user.email}';
        });
      } else {
        setState(() {
          _debugInfo = 'Login test failed - user not found or wrong password';
        });
      }

      await Future.delayed(const Duration(seconds: 2));
      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _debugInfo = 'Login test error: $e';
      });
    }
  }

  Future<void> _clearAllData() async {
    try {
      setState(() {
        _debugInfo = 'Clearing all local data...';
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('users');
      await prefs.remove('conversations');
      await prefs.remove('messages');
      await prefs.remove('usage_analytics');

      setState(() {
        _debugInfo = 'All local data cleared successfully!';
      });

      await Future.delayed(const Duration(seconds: 2));
      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _debugInfo = 'Clear data error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testConnection,
                    child: const Text('Test Connection'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _verifyCollections,
                    child: const Text('Verify Storage'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testBasicOperations,
                    child: const Text('Test Operations'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createTestUser,
                    child: const Text('Create Test User'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testLogin,
                    child: const Text('Test Login'),
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
                    child: const Text('Clear Data'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Currently using local storage (SharedPreferences) for development. PocketBase will be re-enabled later.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
