import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';

class UserRepository {
  static String _stateKey(String username) => 'state::$username';

  // Reads user data from Hive and returns a clean Map
  static Map<String, dynamic>? loadUserData(String username) {
    if (!Hive.isBoxOpen('users')) return null;
    final box = Hive.box('users');
    
    final rawState = box.get(_stateKey(username));
    if (rawState is String && rawState.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawState);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    // Fallback - in case there is no data in Hive, we use the legacy - map.
    final legacy = box.get(username);
    if (legacy is Map) return Map<String, dynamic>.from(legacy);
    
    return null;
  }

  // Saving the data to Hive in a structured way
  static Future<void> saveUserData({
    required String username,
    required double balance,
    required Map<String, int> portfolio,
    required List<Transaction> transactions,
  }) async {
    if (!Hive.isBoxOpen('users')) return;
    final box = Hive.box('users');

    try {
      final rawTransactions = transactions.map((tx) => {
        'symbol': tx.symbol,
        'quantity': tx.quantity,
        'price': tx.price,
        'type': tx.type,
        'timestamp': tx.timestamp.toIso8601String(),
      }).toList();

      final payload = {
        'balance': balance,
        'portfolio': portfolio,
        'transactions': rawTransactions,
      };

      await box.put(_stateKey(username), jsonEncode(payload));
      await box.flush();
      debugPrint("Data saved successfully to Hive via UserRepository");
    } catch (e) {
      debugPrint("Error saving data to Hive: $e");
    }
  }

  // Checking if there is a persisted user in Hive to restore session on app start
  static String? getPersistedCurrentUser() {
    if (!Hive.isBoxOpen('users')) return null;
    final storedCurrent = Hive.box('users').get('__current_user');
    return (storedCurrent is String && storedCurrent.isNotEmpty) ? storedCurrent : null;
  }
}