import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oneai/models/user_model.dart';
import 'package:oneai/services/database_service.dart';
import 'package:oneai/services/pocketbase_service.dart';
import 'package:oneai/services/storage_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'current_user_id';
  static final DatabaseService _dbService = DatabaseService();
  static final PocketBaseService _pbService = PocketBaseService();
  static final StorageManager _storageManager = StorageManager();

  // Get token from secure storage
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Save token to secure storage
  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      print('Token saved successfully');
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  // Save user ID to shared preferences
  static Future<void> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      print('User ID saved: $userId');
    } catch (e) {
      print('Error saving user ID: $e');
    }
  }

  // Get user ID from shared preferences
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      print('Retrieved user ID: $userId');
      return userId;
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Get user based on current storage type
  static Future<UserModel?> getUser() async {
    try {
      final userId = await getUserId();
      print('Getting user for ID: $userId');
      if (userId != null) {
        if (_storageManager.currentStorage == StorageType.pocketbase) {
          return await _getUserFromPocketBase(userId);
        } else {
          return await _dbService.getUserById(userId);
        }
      }
      print('No user ID found');
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  static Future<UserModel?> _getUserFromPocketBase(String userId) async {
    try {
      final record = await _pbService.pb.collection('users').getOne(userId);
      return UserModel(
        id: record.id,
        username: record.data?['username']?.toString() ?? '',
        email: record.data?['email']?.toString() ?? '',
        lastLogin: record.data?['last_login'] != null
            ? DateTime.parse(record.data!['last_login'])
            : null,
        avatarUrl: record.data?['avatar_url']?.toString(),
      );
    } catch (e) {
      print('Error getting user from PocketBase: $e');
      return null;
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      // Logout from PocketBase if using it
      if (_storageManager.currentStorage == StorageType.pocketbase) {
        await _pbService.logout();
      }

      await _storage.delete(key: _tokenKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      print('Logout completed');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      if (_storageManager.currentStorage == StorageType.pocketbase) {
        return _pbService.isAuthenticated;
      } else {
        final token = await getToken();
        final userId = await getUserId();
        final isLoggedIn = token != null && token.isNotEmpty && userId != null;
        print('Is logged in check: $isLoggedIn (token: ${token != null}, userId: ${userId != null})');
        return isLoggedIn;
      }
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Login with storage type detection
  static Future<UserModel> login(String email, String password) async {
    try {
      print('Starting login process for: $email');

      // Validate input
      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Email tidak valid');
      }

      if (password.isEmpty || password.length < 6) {
        throw Exception('Password harus minimal 6 karakter');
      }

      // Try PocketBase first if available
      if (_storageManager.currentStorage == StorageType.pocketbase) {
        try {
          final record = await _pbService.login(email, password);
          final user = UserModel(
            id: record.id,
            username: record.username,
            email: record.email,
            lastLogin: DateTime.now(),
            avatarUrl: record.avatarUrl,
          );

          await saveUserId(user.id);
          final token = _pbService.pb.authStore.token;
          if (token != null && token.isNotEmpty) {
            await saveToken(token);
          }

          print('✅ PocketBase login successful for: ${user.username}');
          return user;
        } catch (e) {
          print('❌ PocketBase login failed, trying local: $e');
          // Fall back to local login
        }
      }

      // Local login
      print('Attempting local database login...');
      final user = await _dbService.loginUser(email, password);

      if (user == null) {
        throw Exception('Email atau password salah');
      }

      print('Database login successful for: ${user.username}');

      // Generate token (simple token for demo)
      final token = 'token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

      // Save token and user ID
      await saveToken(token);
      await saveUserId(user.id);

      print('Login completed successfully');
      return user;
    } catch (e) {
      print('Login failed: $e');
      throw Exception('Login gagal: $e');
    }
  }

  // Register with storage type detection
  static Future<UserModel> register(
      String username, String email, String password) async {
    try {
      print('Starting registration process for: $email');

      // Validate input
      if (username.isEmpty || username.length < 3) {
        throw Exception('Username harus minimal 3 karakter');
      }

      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Email tidak valid');
      }

      if (password.isEmpty || password.length < 6) {
        throw Exception('Password harus minimal 6 karakter');
      }

      // Try PocketBase first if available
      if (_storageManager.currentStorage == StorageType.pocketbase) {
        try {
          final record = await _pbService.register(username, email, password);
          final user = UserModel(
            id: record.id,
            username: record.username,
            email: record.email,
            lastLogin: DateTime.now(),
            avatarUrl: record.avatarUrl,
          );

          await saveUserId(user.id);
          final token = _pbService.pb.authStore.token;
          if (token != null && token.isNotEmpty) {
            await saveToken(token);
          }

          print('✅ PocketBase registration successful for: ${user.username}');
          return user;
        } catch (e) {
          print('❌ PocketBase registration failed, trying local: $e');
          // Fall back to local registration
        }
      }

      // Local registration
      // Check if email already exists
      print('Checking if email exists...');
      final emailExists = await _dbService.emailExists(email);
      if (emailExists) {
        throw Exception('Email sudah terdaftar');
      }

      // Register user to database
      print('Registering user to database...');
      final success = await _dbService.registerUser(username, email, password);

      if (!success) {
        throw Exception('Gagal mendaftarkan user');
      }

      print('Registration successful, attempting auto-login...');
      // Auto-login after register
      return await login(email, password);
    } catch (e) {
      print('Registration failed: $e');
      throw Exception('Registrasi gagal: $e');
    }
  }

  // Get authenticated headers
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // Get user profile
  static Future<UserModel> getUserProfile() async {
    try {
      final user = await getUser();
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }
      return user;
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Gagal mendapatkan profil user: $e');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(UserModel user) async {
    try {
      // Save to current storage
      await saveUserId(user.id);
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Gagal update profil: $e');
    }
  }

  // Change password
  static Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = await getUser();
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      // Verify current password by trying to login
      final loginUser = await _dbService.loginUser(user.email, currentPassword);
      if (loginUser == null) {
        throw Exception('Password saat ini salah');
      }

      // For now, we'll return true as password change would require
      // additional database methods
      return true;
    } catch (e) {
      print('Error changing password: $e');
      throw Exception('Gagal mengubah password: $e');
    }
  }
}
