class Stock {
  final String symbol;
  final double price;
  final String currency;
  final DateTime lastUpdate;

  Stock({
    required this.symbol,
    required this.price,
    required this.currency,
    required this.lastUpdate,
  });

  // changing the factory constructor to match the new API response
  factory Stock.fromJson(String symbol, Map<String, dynamic> json) {
    return Stock(
      symbol: symbol,
      price: (json['rate'] as num).toDouble(), 
      currency: json['currency'] ?? 'USD',
      // server sends date as a string, we need to parse it to DateTime
      lastUpdate: _parseDateTime(json['datetime']),
    );
  }

  static DateTime _parseDateTime(String dateStr) {
    try {
      // server sends date as a string, we need to parse it to DateTime
      return DateTime.parse(dateStr);
    } catch (e) {
      // If parsing fails, use the current time to prevent the app from crashing
      return DateTime.now();
    }
  }
}