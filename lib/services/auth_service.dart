import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oneai/models/user_model.dart';
import 'package:oneai/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'current_user_id';
  static final DatabaseService _dbService = DatabaseService();

  // Mendapatkan token dari secure storage
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Menyimpan token ke secure storage
  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      print('Token saved successfully');
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  // Menyimpan user ID ke shared preferences
  static Future<void> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      print('User ID saved: $userId');
    } catch (e) {
      print('Error saving user ID: $e');
    }
  }

  // Mendapatkan user ID dari shared preferences
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

  // Mendapatkan user dari database
  static Future<UserModel?> getUser() async {
    try {
      final userId = await getUserId();
      print('Getting user for ID: $userId');
      if (userId != null) {
        final user = await _dbService.getUserById(userId);
        print('User found: ${user?.username}');
        return user;
      }
      print('No user ID found');
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Hapus token dan user (logout)
  static Future<void> logout() async {
    try {
      await _storage.delete(key: _tokenKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      print('Logout completed');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      final userId = await getUserId();
      final isLoggedIn = token != null && token.isNotEmpty && userId != null;
      print('Is logged in check: $isLoggedIn (token: ${token != null}, userId: ${userId != null})');
      return isLoggedIn;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Login
  static Future<UserModel> login(String email, String password) async {
    try {
      print('Starting login process for: $email');

      // Validasi input
      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Email tidak valid');
      }

      if (password.isEmpty || password.length < 6) {
        throw Exception('Password harus minimal 6 karakter');
      }

      // Login menggunakan database
      print('Attempting database login...');
      final user = await _dbService.loginUser(email, password);

      if (user == null) {
        throw Exception('Email atau password salah');
      }

      print('Database login successful for: ${user.username}');

      // Generate token (simple token untuk demo)
      final token = 'token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

      // Simpan token dan user ID
      await saveToken(token);
      await saveUserId(user.id);

      print('Login completed successfully');
      return user;
    } catch (e) {
      print('Login failed: $e');
      throw Exception('Login gagal: $e');
    }
  }

  // Register
  static Future<UserModel> register(
      String username, String email, String password) async {
    try {
      print('Starting registration process for: $email');

      // Validasi input
      if (username.isEmpty || username.length < 3) {
        throw Exception('Username harus minimal 3 karakter');
      }

      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Email tidak valid');
      }

      if (password.isEmpty || password.length < 6) {
        throw Exception('Password harus minimal 6 karakter');
      }

      // Cek apakah email sudah terdaftar
      print('Checking if email exists...');
      final emailExists = await _dbService.emailExists(email);
      if (emailExists) {
        throw Exception('Email sudah terdaftar');
      }

      // Register user ke database
      print('Registering user to database...');
      final success = await _dbService.registerUser(username, email, password);

      if (!success) {
        throw Exception('Gagal mendaftarkan user');
      }

      print('Registration successful, attempting auto-login...');
      // Login otomatis setelah register
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
      'Authorization': 'Bearer $token',
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
      // Implementasi update user profile jika diperlukan
      // Untuk sekarang, kita simpan ke shared preferences
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
