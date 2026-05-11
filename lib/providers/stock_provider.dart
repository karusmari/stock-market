import 'dart:async';
import 'package:flutter/material.dart';
import '../models/stock.dart';
import '../services/api_service.dart';

// Transaction model
class Transaction {
  final String symbol;
  final int quantity;
  final double price;
  final String type; // 'buy' või 'sell'
  final DateTime timestamp;

  Transaction({
    required this.symbol,
    required this.quantity,
    required this.price,
    required this.type,
    required this.timestamp,
  });
}

class StockProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  StreamSubscription? _updateSubscription;
  
  // Meie valitud 20 aktsiat - need peavad vastama sample-stocks kaustaski olevate CSV failidele!
  final List<String> _symbols = ['AAME', 'ABM', 'ABT', 'ACU', 'ADM', 'ADP', 'AE', 'AFL', 'AIM', 'AIT', 'ALCO', 'ALX', 'AP', 'APA', 'APD', 'ASA', 'ASB', 'AVT', 'AWR', 'AXR'];
  
  Map<String, Stock> _stocks = {};
  double _balance = 1000000.0; // Kasutaja algne raha
  Map<String, int> _portfolio = {}; // Hoidla: aktsiasümbol -> kogus
  Map<String, double> _previousPrices = {}; // Eelnevad hinnad, et näidata suund
  List<Transaction> _transactions = []; // Tehingute ajalugu
  int _currentIndex = 0;
  
  Map<String, Stock> get stocks => _stocks;
  double get balance => _balance;
  Map<String, int> get portfolio => _portfolio;
  Map<String, double> get previousPrices => _previousPrices;
  List<Transaction> get transactions => _transactions;

  double get totalPortfolioValue {
    double stocksValue = 0;
    _portfolio.forEach((symbol, quantity) {
      if (_stocks.containsKey(symbol)) {
         stocksValue += _stocks[symbol]!.price * quantity;
      } 
    });
    return _balance + stocksValue;
  }

 StockProvider() {
  // Täidame mapi kohe alguses, et kõik 20 rida oleksid olemas
  for (var symbol in _symbols) {
    _stocks[symbol] = Stock(
      symbol: symbol,
      price: 0.0,
      currency: 'USD',         // LISATUD
      lastUpdate: DateTime.now(), // LISATUD
    );
  }
  _startRealTimeUpdates();
}

  void buyStock(String symbol, int quantity) {
    double cost = _stocks[symbol]!.price * quantity;
    if (_balance >= cost) {
      _balance -= cost;
      _portfolio[symbol] = (_portfolio[symbol] ?? 0) + quantity;
      _transactions.add(
        Transaction(
          symbol: symbol,
          quantity: quantity,
          price: _stocks[symbol]!.price,
          type: 'buy',
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
      print('Bought $quantity shares of $symbol for \$${cost.toStringAsFixed(2)}. New balance: \$${_balance.toStringAsFixed(2)}');
    }
  }

  void sellStock(String symbol, int quantity) {
    if (_portfolio[symbol] != null && _portfolio[symbol]! >= quantity) {
      double revenue = _stocks[symbol]!.price * quantity;
      _balance += revenue;
      _portfolio[symbol] = _portfolio[symbol]! - quantity;
      _transactions.add(
        Transaction(
          symbol: symbol,
          quantity: quantity,
          price: _stocks[symbol]!.price,
          type: 'sell',
          timestamp: DateTime.now(),
        ),
      );
      if (_portfolio[symbol] == 0) {
        _portfolio.remove(symbol);
      } 
      notifyListeners();
      print('Sold $quantity shares of $symbol for \$${revenue.toStringAsFixed(2)}. New balance: \$${_balance.toStringAsFixed(2)}');
    }
  }

void _startRealTimeUpdates() {
  _updateSubscription = Stream.periodic(const Duration(milliseconds: 200)).listen((_) {
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
      
      if (updatedStock != null) {
        if (_stocks.containsKey(symbol)) {
          _previousPrices[symbol] = _stocks[symbol]!.price;
        }
        _stocks[symbol] = updatedStock;
        
        // notifyListeners() kutsumine siin võib olla liiga tihe (20 sümbolit x 5 korda = 100x sekundis!)
        // Parem on kutsuda seda ainult siis, kui midagi tõesti muutus
        notifyListeners();
      }
    } catch (e) {
      // Vaikne fail
    }
  }

  @override
  void dispose() {
    _updateSubscription?.cancel(); // Väga tähtis: sulge voog, kui äpp kinni pannakse!
    super.dispose();
  }
}