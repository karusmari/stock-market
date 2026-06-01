import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock.dart';
import '../models/historical_point.dart';
import 'package:intl/intl.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5001';

  // asking the list of available stocks from the server (we have 20, but this makes it dynamic)
  Future<List<String>> fetchStocksList() async {
    final response = await http.get(Uri.parse('$baseUrl/stocks_list'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => item.toString()).toList();
    } else {
      throw Exception('Error fetching stocks list');
    }
  }

  // asking for the current price of a specific stock
  Future<Stock> fetchExchangeRate(String symbol) async {
    final response = await http
        .get(Uri.parse('$baseUrl/exchange_rate/$symbol'))
        .timeout(
          const Duration(seconds: 1),
        ); // if the server doesn't respond within 1 second, we consider it a failure

    if (response.statusCode == 200) {
      return Stock.fromJson(symbol, json.decode(response.body));
    } else {
      throw Exception('Error fetching exchange rate for $symbol');
    }
  }

  // fetch historical data for a stock - this is used in the detail screen to show the price history chart
  Future<List<HistoricalPoint>> fetchStockHistory(
    String symbol, {
    int days = 365,
    }) async {
      try {
        final now = DateTime.now();
        final startDate = now.subtract(Duration(days: days)).toIso8601String().split('T').first;
        final endDate = now.toIso8601String().split('T').first;

        final url = Uri.parse('$baseUrl/hist/$symbol?start_date=$startDate&end_date=$endDate');
        print('Querying history for $symbol with URL: $url');

        final response = await http.get(url).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);

          if (data.containsKey('values') && data['values'] is List) {
            final List<dynamic> values = data['values'];

            // using the same date format as the server to ensure correct parsing
            final DateFormat serverFormat = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US');

            final List<HistoricalPoint> points = [];

            for (var item in values) {
              try {
                // cleaning the date string - sometimes there might be extra spaces or different formatting, so we trim it and ensure it's in the expected format
                final String dateStr = item['date'].toString().trim();
                
                // parsing the date using the server's format - this is crucial for correct date handling, 
                // especially if the server is in a different timezone or locale
                final DateTime dt = serverFormat.parse(dateStr);
                final double closePrice = (item['close'] as num?)?.toDouble() ?? 0.0;

                points.add(HistoricalPoint(
                  date: dt,
                  close: closePrice,
                ));
              } catch (e) {
                // If a specific row fails to parse, we log it but continue with the rest
                print("Error parsing specific point: ${item['date']} -> $e");
              }
            }

            print('Successfully loaded ${points.length} points for $symbol');
            return points;
          }
        } else {
          print('Server error: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        print('Error fetching history for $symbol: $e');
      }

      return []; // On error, we return an empty list
    }

  // Auth endpoints
  /// Register a new user. Returns true on success.
  Future<bool> registerUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    return response.statusCode == 201;
  }

  /// Login existing user. Returns true on success.
  Future<bool> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    return response.statusCode == 200;
  }
}
