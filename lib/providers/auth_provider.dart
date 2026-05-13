import 'package:flutter/material.dart';
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
    _currentUser = null;
    notifyListeners();
  }
}
