import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/stock.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class StockProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  StreamSubscription? _updateSubscription;

  // Meie valitud 20 aktsiat - need peavad vastama sample-stocks kaustaski olevate CSV failidele!
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

  Map<String, Stock> _stocks = {};
  // Per-user state
  Map<String, double> _balancesByUser = {}; // username -> balance
  Map<String, Map<String, int>> _portfoliosByUser =
      {}; // username -> (symbol -> qty)
  Map<String, double> _previousPrices = {}; // Eelnevad hinnad, et näidata suund
  Map<String, List<Transaction>> _transactionsByUser =
      {}; // username -> transactions
  int _currentIndex = 0;

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
    // Täidame mapi kohe alguses, et kõik 20 rida oleksid olemas
    for (var symbol in _symbols) {
      _stocks[symbol] = Stock(
        symbol: symbol,
        price: 0.0,
        currency: 'EUR', // LISATUD
        lastUpdate: DateTime.now(), // LISATUD
      );
    }
    _startRealTimeUpdates();
  }

  // Ensure the user has an initialized entry
  void _ensureUser(String username) {
    // Use a shared 'users' box (opened at app startup) to persist per-user data.
    Map? userData;
    if (Hive.isBoxOpen('users')) {
      final box = Hive.box('users');
      userData = box.get(username) as Map?;
    }

    final storedBalance = userData != null
        ? (userData['balance'] as double?)
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
      if (storedTransactions != null) {
        try {
          return List<Transaction>.from(storedTransactions.cast<Transaction>());
        } catch (_) {
          return <Transaction>[];
        }
      }
      return <Transaction>[];
    });
  }

  /// Public wrapper to initialize per-user state (call after login)
  void ensureUser(String username) => _ensureUser(username);

  // Buy for specific user
  void buyStockFor(String username, String symbol, int quantity) {
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
      _saveUserToStorage(username);
      notifyListeners();
      print(
        '[$username] Bought $quantity $symbol for \$${cost.toStringAsFixed(2)}. New balance: \$${_balancesByUser[username]!.toStringAsFixed(2)}',
      );
    }
  }

  // Sell for specific user
  void sellStockFor(String username, String symbol, int quantity) {
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
      _saveUserToStorage(username);
      if (portfolio[symbol] == 0) portfolio.remove(symbol);
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
          // Küsime korraga ainult 4 aktsiat, et server ellu jääks
          for (int i = 0; i < 4; i++) {
            if (_currentIndex >= _symbols.length) _currentIndex = 0;

            String symbol = _symbols[_currentIndex];
            _updateSingleStock(symbol);

            _currentIndex++;
          }
          // Kuna me uuendame pidevalt, siis notifyListeners on juba _updateSingleStock sees
        });
  }

  // Eraldi meetod ühe aktsia uuendamiseks
  Future<void> _updateSingleStock(String symbol) async {
    try {
      final updatedStock = await _apiService.fetchExchangeRate(symbol);
      if (_stocks.containsKey(symbol)) {
        _previousPrices[symbol] = _stocks[symbol]!.price;
      }
      _stocks[symbol] = updatedStock;

      // notifyListeners() kutsumine siin võib olla liiga tihe (20 sümbolit x 5 korda = 100x sekundis!)
      // Parem on kutsuda seda ainult siis, kui midagi tõesti muutus
      notifyListeners();
    } catch (e) {
      // Vaikne fail
    }
  }

  // Persist per-user state into Hive box
  void _saveUserToStorage(String username) {
    if (!Hive.isBoxOpen('users')) return;
    final box = Hive.box('users');
    try {
      box.put(username, {
        'balance': _balancesByUser[username],
        'portfolio': _portfoliosByUser[username],
        'transactions': _transactionsByUser[username],
      });
    } catch (e) {
      // ignore persistence errors for now
    }
  }

  @override
  void dispose() {
    _updateSubscription
        ?.cancel(); // Väga tähtis: sulge voog, kui äpp kinni pannakse!
    super.dispose();
  }
}
