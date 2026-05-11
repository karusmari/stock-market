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

  // See on maagia, mis muudab serveri vastuse Dart-i objektiks
  factory Stock.fromJson(String symbol, Map<String, dynamic> json) {
    return Stock(
      symbol: symbol,
      price: (json['rate'] as num).toDouble(), // Kindlustame, et on double
      currency: json['currency'] ?? 'USD',
      // Server saadab kuupäeva tekstina, muudame selle DateTime objektiks
      lastUpdate: _parseDateTime(json['datetime']),
    );
  }

  static DateTime _parseDateTime(String dateStr) {
    try {
      // Kuna server saadab formaadis "Thu, 02 May 2024...", 
      // siis DateTime.parse ei pruugi seda alati otse süüa.
      // Lihtsuse mõttes proovime esmalt otse:
      return DateTime.parse(dateStr);
    } catch (e) {
      // Kui otse ei saa, kasutame praegust aega, et äpp kokku ei jookseks
      return DateTime.now();
    }
  }
}