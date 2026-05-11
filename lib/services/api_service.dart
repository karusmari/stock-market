import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock.dart';

class ApiService {
  // localhosti aadress emulaatoris/simulaatoris on tavaliselt see
  static const String baseUrl = 'http://127.0.0.1:5001';

  // 1. Küsime nimekirja kõigist aktsiatest
  Future<List<String>> fetchStocksList() async {
    final response = await http.get(Uri.parse('$baseUrl/stocks_list'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => item.toString()).toList();
    } else {
      throw Exception('Error fetching stocks list');
    }
  }

  // 2. Küsime ühe konkreetse aktsia hetkehindu
  Future<Stock> fetchExchangeRate(String symbol) async {
    final response = await http
        .get(Uri.parse('$baseUrl/exchange_rate/$symbol'))
        .timeout(
          const Duration(seconds: 1),
        ); // Kui server ei vasta 1 sekundiga, katkestame päringu

    if (response.statusCode == 200) {
      return Stock.fromJson(symbol, json.decode(response.body));
    } else {
      throw Exception('Error fetching exchange rate for $symbol');
    }
  }

  Future<List<double>> fetchStockHistory(String symbol) async {
    try {
      final now = DateTime.now();
      final startDate = now
          .subtract(const Duration(days: 30))
          .toIso8601String();
      final endDate = now.toIso8601String();

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/hist/$symbol?start_date=$startDate&end_date=$endDate',
            ),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Server returns: {"currency": "USD", "values": [{"date": "...", "close": 100.5}, ...]}
        if (data.containsKey('values')) {
          final List<dynamic> values = data['values'];
          return values
              .map((item) => (item['close'] as num).toDouble())
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error querying history for $symbol: $e');
      return [];
    }
  }
}
