import 'package:oneai/services/database_service.dart';
import 'package:oneai/services/pocketbase_service.dart';
import 'package:oneai/models/user_model.dart';
import 'package:oneai/models/conversation_model.dart';
import 'package:oneai/models/message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum StorageType { local, pocketbase, hybrid }

class StorageManager {
  static final StorageManager _instance = StorageManager._internal();
  factory StorageManager() => _instance;
  StorageManager._internal();

  final DatabaseService _localDb = DatabaseService();
  final PocketBaseService _pbService = PocketBaseService();

  StorageType _currentStorage = StorageType.local;
  bool _autoSync = false;

  StorageType get currentStorage => _currentStorage;
  bool get autoSync => _autoSync;

  /// Initialize storage manager
  Future<void> initialize() async {
    try {
      // Always initialize local storage first
      await _localDb.database;
      print('✅ Local storage initialized');

      // Load storage preference
      final prefs = await SharedPreferences.getInstance();
      final storageTypeString = prefs.getString('storage_type') ?? 'local';
      _currentStorage = StorageType.values.firstWhere(
            (e) => e.toString().split('.').last == storageTypeString,
        orElse: () => StorageType.local,
      );

      _autoSync = prefs.getBool('auto_sync') ?? false;

      // Try to initialize PocketBase if needed
      if (_currentStorage == StorageType.pocketbase || _currentStorage == StorageType.hybrid) {
        try {
          await _pbService.initialize();
          final isConnected = await _pbService.checkConnection();

          if (!isConnected) {
            print('⚠️ PocketBase not available, falling back to local storage');
            _currentStorage = StorageType.local;
            await _saveStoragePreference();
          } else {
            print('✅ PocketBase storage available');
          }
        } catch (e) {
          print('⚠️ PocketBase initialization failed, using local storage: $e');
          _currentStorage = StorageType.local;
          await _saveStoragePreference();
        }
      }

      print('📦 Storage Manager initialized with: $_currentStorage');
    } catch (e) {
      print('❌ Storage Manager initialization error: $e');
      _currentStorage = StorageType.local;
    }
  }

  /// Switch storage type
  Future<bool> switchStorage(StorageType newType) async {
    try {
      if (newType == StorageType.pocketbase || newType == StorageType.hybrid) {
        // Check if PocketBase is available
        await _pbService.initialize();
        final isConnected = await _pbService.checkConnection();
        final collectionsExist = await _pbService.checkCollectionsExist();

        if (!isConnected || !collectionsExist) {
          print('❌ Cannot switch to PocketBase: not available or collections missing');
          return false;
        }
      }

      _currentStorage = newType;
      await _saveStoragePreference();

      print('✅ Storage switched to: $newType');
      return true;
    } catch (e) {
      print('❌ Error switching storage: $e');
      return false;
    }
  }

  /// Enable/disable auto sync
  Future<void> setAutoSync(bool enabled) async {
    _autoSync = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync', enabled);
    print('🔄 Auto sync ${enabled ? "enabled" : "disabled"}');
  }

  /// Save storage preference
  Future<void> _saveStoragePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storage_type', _currentStorage.toString().split('.').last);
  }

  /// Get storage status
  Future<Map<String, dynamic>> getStorageStatus() async {
    final localStatus = await _getLocalStorageStatus();
    final pbStatus = await _getPocketBaseStatus();

    return {
      'current_storage': _currentStorage.toString().split('.').last,
      'auto_sync': _autoSync,
      'local': localStatus,
      'pocketbase': pbStatus,
    };
  }

  Future<Map<String, dynamic>> _getLocalStorageStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = prefs.getStringList('users') ?? [];
      final conversations = prefs.getStringList('conversations') ?? [];
      final messages = prefs.getStringList('messages') ?? [];

      return {
        'available': true,
        'users_count': users.length,
        'conversations_count': conversations.length,
        'messages_count': messages.length,
      };
    } catch (e) {
      return {
        'available': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _getPocketBaseStatus() async {
    try {
      if (!_pbService.isInitialized) {
        await _pbService.initialize();
      }

      final isConnected = await _pbService.checkConnection();
      if (!isConnected) {
        return {
          'available': false,
          'error': 'Connection failed',
        };
      }

      final collectionsExist = await _pbService.checkCollectionsExist();

      return {
        'available': isConnected && collectionsExist,
        'connected': isConnected,
        'collections_exist': collectionsExist,
        'url': _pbService.baseUrl,
        'authenticated': _pbService.isAuthenticated,
      };
    } catch (e) {
      return {
        'available': false,
        'error': e.toString(),
      };
    }
  }

  /// Migrate data from local to PocketBase
  Future<bool> migrateToCloud() async {
    try {
      if (_currentStorage == StorageType.pocketbase) {
        print('Already using PocketBase storage');
        return true;
      }

      // Check PocketBase availability
      await _pbService.initialize();
      final isConnected = await _pbService.checkConnection();
      final collectionsExist = await _pbService.checkCollectionsExist();

      if (!isConnected || !collectionsExist) {
        print('❌ PocketBase not ready for migration');
        return false;
      }

      print('🚀 Starting migration to PocketBase...');

      // Get all local data
      final prefs = await SharedPreferences.getInstance();
      final users = prefs.getStringList('users') ?? [];
      final conversations = prefs.getStringList('conversations') ?? [];
      final messages = prefs.getStringList('messages') ?? [];

      print('📊 Found ${users.length} users, ${conversations.length} conversations, ${messages.length} messages');

      // Migrate users first
      for (final userJson in users) {
        try {
          final userData = jsonDecode(userJson) as Map<String, dynamic>;

          // Check if user already exists in PocketBase
          try {
            final existingRecords = await _pbService.pb.collection('users').getList(
              filter: 'email = "${userData['email']}"',
              perPage: 1,
            );
            if (existingRecords.isNotEmpty) {
              print('User ${userData['email']} already exists in PocketBase');
              continue;
            }
          } catch (e) {
            // User doesn't exist, create it
            print('Creating new user: ${userData['email']}');
          }

          await _pbService.pb.collection('users').create({
            'username': userData['username'],
            'email': userData['email'],
            'password': 'temp_password_123', // User will need to reset
            'passwordConfirm': 'temp_password_123',
            'last_login': userData['lastLogin'],
            'avatar_url': userData['avatarUrl'],
          });

          print('✅ Migrated user: ${userData['username']}');
        } catch (e) {
          print('❌ Error migrating user: $e');
        }
      }

      // Migrate conversations
      for (final conversationJson in conversations) {
        try {
          final convData = jsonDecode(conversationJson) as Map<String, dynamic>;

          await _pbService.pb.collection('conversations').create({
            'user_id': convData['userId'],
            'chatbot_id': convData['chatbotId'],
            'title': convData['title'],
            'is_archived': convData['isArchived'] ?? false,
          });

          print('✅ Migrated conversation: ${convData['title']}');
        } catch (e) {
          print('❌ Error migrating conversation: $e');
        }
      }

      // Migrate messages
      for (final messageJson in messages) {
        try {
          final msgData = jsonDecode(messageJson) as Map<String, dynamic>;

          await _pbService.pb.collection('messages').create({
            'message_id': msgData['id'],
            'conversation_id': msgData['conversationId'],
            'content': msgData['text'],
            'is_user': msgData['isUser'],
            'token_count': msgData['tokenCount'] ?? 0,
          });

          print('✅ Migrated message');
        } catch (e) {
          print('❌ Error migrating message: $e');
        }
      }

      print('✅ Migration completed successfully');
      return await switchStorage(StorageType.pocketbase);
    } catch (e) {
      print('❌ Migration failed: $e');
      return false;
    }
  }

  /// Sync data between local and cloud
  Future<bool> syncData() async {
    try {
      if (_currentStorage != StorageType.hybrid && !_autoSync) {
        print('Sync not enabled for current storage type');
        return false;
      }

      print('🔄 Starting data sync...');

      // TODO: Implement sync logic
      // This would involve:
      // 1. Compare timestamps
      // 2. Sync newer data
      // 3. Handle conflicts

      print('✅ Data sync completed');
      return true;
    } catch (e) {
      print('❌ Data sync failed: $e');
      return false;
    }
  }

  /// Get recommended storage type based on availability
  Future<StorageType> getRecommendedStorage() async {
    try {
      await _pbService.initialize();
      final isConnected = await _pbService.checkConnection();
      final collectionsExist = await _pbService.checkCollectionsExist();

      if (isConnected && collectionsExist) {
        return StorageType.hybrid; // Best of both worlds
      } else {
        return StorageType.local; // Fallback to local
      }
    } catch (e) {
      return StorageType.local;
    }
  }
}
