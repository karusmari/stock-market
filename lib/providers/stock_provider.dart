import 'dart:async';
import 'package:flutter/material.dart';
import '../models/stock.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/user_repository.dart'; 

class StockProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  StreamSubscription? _updateSubscription;
  int _currentIndex = 0;

  final List<String> _symbols = [
    'AAME', 'ADP', 'ALX', 'ABT', 'ADM', 'FARM', 'HELE', 'IBM', 'PBI', 'RAD',
    'ALCO', 'TRV', 'AP', 'APA', 'UVV', 'WELL', 'WGO', 'WMT', 'WRB', 'XRX'
  ];

  // the in-memory state of the app - we keep all stocks, user balances, portfolios and transactions here for simplicity. 
  // In a real app, we would likely split this into multiple providers and use a more robust state management solution.
  final Map<String, Stock> _stocks = {};
  final Map<String, double> _previousPrices = {};
  final Map<String, double> _balancesByUser = {};
  final Map<String, Map<String, int>> _portfoliosByUser = {};
  final Map<String, List<Transaction>> _transactionsByUser = {};

  // Getters
  Map<String, Stock> get stocks => _stocks;
  Map<String, double> get previousPrices => _previousPrices;
  Map<String, int> portfolioFor(String username) => _portfoliosByUser[username] ?? {};
  double balanceFor(String username) => _balancesByUser[username] ?? 0.0;
  List<Transaction> transactionsFor(String username) => _transactionsByUser[username] ?? [];

  double totalPortfolioValueFor(String username) {
    double stocksValue = 0;
    portfolioFor(username).forEach((symbol, quantity) {
      if (_stocks.containsKey(symbol)) {
        stocksValue += _stocks[symbol]!.price * quantity;
      }
    });
    return balanceFor(username) + stocksValue;
  }

  // Constructor - we initialize the stock list and start the real-time updates
  StockProvider() {
    // Creating initial stock entries with price 0 to ensure the UI has something to display before the first API call completes. 
    // This prevents null errors in the UI and allows for a smoother user experience as prices load in real-time.
    for (var symbol in _symbols) {
      _stocks[symbol] = Stock(symbol: symbol, price: 0.0, currency: 'USD', lastUpdate: DateTime.now());
    }
    
    // Restoring the last logged in user and their data from Hive storage, if available. 
    final lastUser = UserRepository.getPersistedCurrentUser();
    if (lastUser != null) _ensureUser(lastUser);

    _startRealTimeUpdates();
  }

  // Loading the user data from Hive storage if it exists, otherwise initializing with default values.
  void _ensureUser(String username) {
    if (_balancesByUser.containsKey(username)) return; // user already initialized

    final userData = UserRepository.loadUserData(username);

    // Restoring the balance (value 1 000 000)
    _balancesByUser[username] = (userData?['balance'] as num?)?.toDouble() ?? 1000000.0;

    // Restoring the portfolio (empty by default)
    _portfoliosByUser[username] = {};
    if (userData?['portfolio'] is Map) {
      (userData!['portfolio'] as Map).forEach((k, v) {
        _portfoliosByUser[username]![k as String] = (v as num).toInt();
      });
    }

    // Restoring the transaction history
    _transactionsByUser[username] = [];
    if (userData?['transactions'] is List) {
      for (final tx in (userData!['transactions'] as List)) {
        try {
          _transactionsByUser[username]!.add(Transaction(
            symbol: tx['symbol'],
            quantity: (tx['quantity'] as num).toInt(),
            price: (tx['price'] as num).toDouble(),
            type: tx['type'],
            timestamp: DateTime.parse(tx['timestamp']),
          ));
        } catch (_) {} // in case of any parsing error, we skip that transaction to prevent the app from crashing
      }
    }
  }

  void ensureUser(String username) => _ensureUser(username);

  // BUYING LOGIC
  Future<void> buyStockFor(String username, String symbol, int quantity) async {
    _ensureUser(username);
    double cost = _stocks[symbol]!.price * quantity;
    
    if (balanceFor(username) >= cost) {
      _balancesByUser[username] = balanceFor(username) - cost;
      portfolioFor(username)[symbol] = (portfolioFor(username)[symbol] ?? 0) + quantity;
      
      _transactionsByUser[username]!.add(Transaction(
        symbol: symbol, quantity: quantity, price: _stocks[symbol]!.price, type: 'buy', timestamp: DateTime.now(),
      ));

      await _syncUserWithStorage(username);
      notifyListeners();
    }
  }

  // SELLING LOGIC
  Future<void> sellStockFor(String username, String symbol, int quantity) async {
    _ensureUser(username);
    final portfolio = portfolioFor(username);
    
    if ((portfolio[symbol] ?? 0) >= quantity) {
      double revenue = _stocks[symbol]!.price * quantity;
      _balancesByUser[username] = balanceFor(username) + revenue;
      portfolio[symbol] = portfolio[symbol]! - quantity;
      
      _transactionsByUser[username]!.add(Transaction(
        symbol: symbol, quantity: quantity, price: _stocks[symbol]!.price, type: 'sell', timestamp: DateTime.now(),
      ));

      if (portfolio[symbol] == 0) portfolio.remove(symbol);

      await _syncUserWithStorage(username);
      notifyListeners();
    }
  }

  // Real-time updates (5x sec, 4 at a time)
  void _startRealTimeUpdates() {
    _updateSubscription = Stream.periodic(const Duration(milliseconds: 200)).listen((_) {
      for (int i = 0; i < 4; i++) {
        if (_currentIndex >= _symbols.length) _currentIndex = 0;
        _updateSingleStock(_symbols[_currentIndex]);
        _currentIndex++;
      }
    });
  }

  Future<void> _updateSingleStock(String symbol) async {
    try {
      final updatedStock = await _apiService.fetchExchangeRate(symbol);
      if (_stocks.containsKey(symbol)) {
        _previousPrices[symbol] = _stocks[symbol]!.price;
      }
      _stocks[symbol] = updatedStock;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating stock $symbol: $e');
    }
  }

  // helper to sync the in-memory state with Hive storage after every transaction
  Future<void> _syncUserWithStorage(String username) async {
    await UserRepository.saveUserData(
      username: username,
      balance: balanceFor(username),
      portfolio: portfolioFor(username),
      transactions: transactionsFor(username),
    );
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    super.dispose();
  }
}