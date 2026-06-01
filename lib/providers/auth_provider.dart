import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  String? _currentUser;
  String? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  String? lastError;

  /// Attempt to login via API. Returns true on success.
  Future<bool> loginWithPassword(String username, String password) async {
    lastError = null;
    try {
      final ok = await _api.loginUser(username, password);
      if (ok) {
        _currentUser = username;
        // Persist currently logged in user so web reloads/hot restarts restore session
        if (Hive.isBoxOpen('users')) {
          final box = Hive.box('users');
          try {
            box.put('__current_user', username);
          } catch (_) {}
        }
        notifyListeners();
        return true;
      }
      lastError = 'Invalid credentials';
      return false;
    } catch (e) {
      lastError = 'Login error';
      return false;
    }
  }

  Future<bool> registerWithPassword(String username, String password) async {
    lastError = null;
    try {
      final ok = await _api.registerUser(username, password);
      if (ok) {
        _currentUser = username;
        if (Hive.isBoxOpen('users')) {
          final box = Hive.box('users');
          try {
            box.put('__current_user', username);
          } catch (_) {}
        }
        notifyListeners();
        return true;
      }
      lastError = 'Registration failed (user exists?)';
      return false;
    } catch (e) {
      lastError = 'Registration error';
      return false;
    }
  }

  void logout() {
    // Clear persisted current user
    if (Hive.isBoxOpen('users')) {
      final box = Hive.box('users');
      try {
        box.delete('__current_user');
      } catch (_) {}
    }
    _currentUser = null;
    notifyListeners();
  }

  /// Try to restore previously logged-in user from storage.
  void restoreSession() {
    if (Hive.isBoxOpen('users')) {
      final box = Hive.box('users');
      final stored = box.get('__current_user');
      if (stored is String) {
        _currentUser = stored;
        notifyListeners();
      }
    }
  }
}
