import 'package:flutter/material.dart';
import 'package:oneai/models/user_model.dart';
import 'package:oneai/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  AuthProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      print("Checking if user is logged in...");
      final isLoggedIn = await AuthService.isLoggedIn();
      print("Is logged in: $isLoggedIn");

      if (isLoggedIn) {
        _user = await AuthService.getUser();
        print("User loaded: ${_user?.username}");
        if (_user == null) {
          // If we have a token but no user, try to get the user profile
          try {
            _user = await AuthService.getUserProfile();
            print("User profile loaded: ${_user?.username}");
          } catch (e) {
            print("Error getting user profile: $e");
            // If there's an error getting the user, consider them logged out
            await AuthService.logout();
            _user = null;
          }
        }
      }
      _error = null;
    } catch (e) {
      print("Error initializing user: $e");
      _error = e.toString();
      // If there's an error getting the user, consider them logged out
      await AuthService.logout();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("Attempting login for: $email");
      _user = await AuthService.login(email, password);
      print("Login successful for: ${_user?.username}");
      _error = null;
      return true;
    } catch (e) {
      print("Login error: $e");
      _error = e.toString();
      _user = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("Attempting registration for: $email");
      _user = await AuthService.register(username, email, password);
      print("Registration successful for: ${_user?.username}");
      _error = null;
      return true;
    } catch (e) {
      print("Registration error: $e");
      _error = e.toString();
      _user = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.logout();
      _user = null;
      _error = null;
      print("Logout successful");
    } catch (e) {
      print("Logout error: $e");
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUserProfile() async {
    if (!isAuthenticated) return;

    _isLoading = true;
    notifyListeners();

    try {
      _user = await AuthService.getUserProfile();
      _error = null;
    } catch (e) {
      print("Error refreshing user profile: $e");
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
