import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/stock.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class StockProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  StreamSubscription? _updateSubscription;

  // the chosen 20 stocks
  final List<String> _symbols = [
    'AAME',
    'ABM',
    'ABT',
    'ACU',
    'ADM',
    'ADP',
    'AE',
    'AFL',
    'AIM',
    'AIT',
    'ALCO',
    'ALX',
    'AP',
    'APA',
    'APD',
    'ASA',
    'ASB',
    'AVT',
    'AWR',
    'AXR',
  ];

  final Map<String, Stock> _stocks = {};
  final Map<String, double> _balancesByUser = {}; // username -> balance
  final Map<String, Map<String, int>> _portfoliosByUser = {}; // username -> (symbol -> qty)
  final Map<String, double> _previousPrices = {}; // Previous prices to show trend
  final Map<String, List<Transaction>> _transactionsByUser = {}; // username -> transactions
  int _currentIndex = 0;

  String _stateKey(String username) => 'state::$username';

  Map<String, Stock> get stocks => _stocks;
  Map<String, double> get previousPrices => _previousPrices;

  // NOTE: per-user accessors
  Map<String, int> portfolioFor(String username) =>
      _portfoliosByUser[username] ?? {};
  double balanceFor(String username) => _balancesByUser[username] ?? 0.0;
  List<Transaction> transactionsFor(String username) =>
      _transactionsByUser[username] ?? [];

  double totalPortfolioValueFor(String username) {
    double stocksValue = 0;
    final portfolio = portfolioFor(username);
    portfolio.forEach((symbol, quantity) {
      if (_stocks.containsKey(symbol)) {
        stocksValue += _stocks[symbol]!.price * quantity;
      }
    });
    return balanceFor(username) + stocksValue;
  }

  StockProvider() {
    // filling the map from the beginning
    for (var symbol in _symbols) {
      _stocks[symbol] = Stock(
        symbol: symbol,
        price: 0.0,
        currency: 'USD',
        lastUpdate: DateTime.now(), 
      );
    }
    // Try to restore per-user state if an active user was persisted (web hot reload)
    try {
      if (Hive.isBoxOpen('users')) {
        final box = Hive.box('users');
        final storedCurrent = box.get('__current_user');
        if (storedCurrent is String && storedCurrent.isNotEmpty) {
          _ensureUser(storedCurrent);
        }
      }
    } catch (_) {}

    _startRealTimeUpdates();
  }

  // Ensure the user has an initialized entry
  void _ensureUser(String username) {
    // Use a shared 'users' box (opened at app startup) to persist per-user data.
    Map<String, dynamic>? userData;
    if (Hive.isBoxOpen('users')) {
      final box = Hive.box('users');
      final rawState = box.get(_stateKey(username));
      if (rawState is String && rawState.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawState);
          if (decoded is Map) {
            userData = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // Ignore malformed JSON and fallback to legacy storage.
        }
      }

      if (userData == null) {
        final legacy = box.get(username);
        if (legacy is Map) {
          userData = Map<String, dynamic>.from(legacy);
        }
      }
    }

    final storedBalance = userData != null
      ? (userData['balance'] as num?)?.toDouble()
      : null;
    final storedPortfolio = userData != null
        ? (userData['portfolio'] as Map?)
        : null;
    final storedTransactions = userData != null
        ? (userData['transactions'] as List?)
        : null;

    _balancesByUser[username] = storedBalance ?? 1000000.0;
    _portfoliosByUser.putIfAbsent(username, () {
      if (storedPortfolio != null) {
        return Map<String, int>.from(
          storedPortfolio.map(
            (k, v) => MapEntry(k as String, (v as num).toInt()),
          ),
        );
      }
      return <String, int>{};
    });
    _transactionsByUser.putIfAbsent(username, () {
      if (storedTransactions == null) {
        return <Transaction>[];
      }

      final parsedTransactions = <Transaction>[];
      for (final txData in storedTransactions) {
        try {
          final map = Map<String, dynamic>.from(txData as Map);
          final symbol = map['symbol'] as String?;
          final quantity = map['quantity'] as num?;
          final price = map['price'] as num?;
          final type = map['type'] as String?;
          final timestampRaw = map['timestamp'] as String?;
          final timestamp =
              timestampRaw != null ? DateTime.tryParse(timestampRaw) : null;

          if (symbol == null ||
              quantity == null ||
              price == null ||
              type == null ||
              timestamp == null) {
            continue;
          }

          parsedTransactions.add(
            Transaction(
              symbol: symbol,
              quantity: quantity.toInt(),
              price: price.toDouble(),
              type: type,
              timestamp: timestamp,
            ),
          );
        } catch (_) {
          // Skip malformed rows but keep valid history entries.
        }
      }
      return parsedTransactions;
    });
  }

  /// Public wrapper to initialize per-user state (call after login)
  void ensureUser(String username) => _ensureUser(username);

  // Buy for specific user
  Future<void> buyStockFor(String username, String symbol, int quantity) async {
    _ensureUser(username);
    double cost = _stocks[symbol]!.price * quantity;
    if (_balancesByUser[username]! >= cost) {
      _balancesByUser[username] = _balancesByUser[username]! - cost;
      final portfolio = _portfoliosByUser[username]!;
      portfolio[symbol] = (portfolio[symbol] ?? 0) + quantity;
      final tx = Transaction(
        symbol: symbol,
        quantity: quantity,
        price: _stocks[symbol]!.price,
        type: 'buy',
        timestamp: DateTime.now(),
      );
      _transactionsByUser[username]!.add(tx);
      await _saveUserToStorage(username);
      notifyListeners();
      print(
        '[$username] Bought $quantity $symbol for \$${cost.toStringAsFixed(2)}. New balance: \$${_balancesByUser[username]!.toStringAsFixed(2)}',
      );
    }
  }

  // Sell for specific user
  Future<void> sellStockFor(String username, String symbol, int quantity) async {
    _ensureUser(username);
    final portfolio = _portfoliosByUser[username]!;
    if (portfolio[symbol] != null && portfolio[symbol]! >= quantity) {
      double revenue = _stocks[symbol]!.price * quantity;
      _balancesByUser[username] = _balancesByUser[username]! + revenue;
      portfolio[symbol] = portfolio[symbol]! - quantity;
      final tx = Transaction(
        symbol: symbol,
        quantity: quantity,
        price: _stocks[symbol]!.price,
        type: 'sell',
        timestamp: DateTime.now(),
      );
      _transactionsByUser[username]!.add(tx);
      if (portfolio[symbol] == 0) portfolio.remove(symbol);
      await _saveUserToStorage(username);
      notifyListeners();
      print(
        '[$username] Sold $quantity $symbol for \$${revenue.toStringAsFixed(2)}. New balance: \$${_balancesByUser[username]!.toStringAsFixed(2)}',
      );
    }
  }

  // NOTE: use buyStockFor / sellStockFor for per-user operations

  void _startRealTimeUpdates() {
    _updateSubscription = Stream.periodic(const Duration(milliseconds: 200))
        .listen((_) {
          // asking just 4 stocks at a time to avoid hitting API limits and to spread out the load
          for (int i = 0; i < 4; i++) {
            if (_currentIndex >= _symbols.length) _currentIndex = 0;

            String symbol = _symbols[_currentIndex];
            _updateSingleStock(symbol);

            _currentIndex++;
          }
        });
  }

  // updating a single stock - this is called every 200ms for 4 stocks
  Future<void> _updateSingleStock(String symbol) async {
    try {
      final updatedStock = await _apiService.fetchExchangeRate(symbol);
      if (_stocks.containsKey(symbol)) {
        _previousPrices[symbol] = _stocks[symbol]!.price;
      }
      _stocks[symbol] = updatedStock;

      notifyListeners();
    } catch (e) {
      // Vaikne fail
    }
  }

  // Persist per-user state into Hive box
  Future<void> _saveUserToStorage(String username) async {
    if (!Hive.isBoxOpen('users')) return;
    final box = Hive.box('users');
    try {
      final rawTransactions = _transactionsByUser[username]?.map((tx) => {
      'symbol': tx.symbol,
      'quantity': tx.quantity,
      'price': tx.price,
      'type': tx.type,
      'timestamp': tx.timestamp.toIso8601String(),
    }).toList() ?? [];

      final payload = {
        'balance': _balancesByUser[username],
        'portfolio': _portfoliosByUser[username],
        'transactions': rawTransactions,
      };

      await box.put(_stateKey(username), jsonEncode(payload));
      await box.flush();
      print("Data is saved successfully into Hive");
    } catch (e) {
      print("Error saving data into Hive");
      // ignore persistence errors for now
    }
  }

  @override
  void dispose() {
    _updateSubscription
        ?.cancel(); // in case provider is disposed, stop the updates to prevent memory leaks
    super.dispose();
  }
}
