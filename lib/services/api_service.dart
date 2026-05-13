import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock.dart';
import '../models/historical_point.dart';
import 'package:intl/intl.dart';

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

  Future<List<HistoricalPoint>> fetchStockHistory(
    String symbol, {
    int days = 180,
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

            // OLULINE: Lisa 'en_US', et ta oskaks lugeda "Fri" ja "Nov"
            // Kui intl pakett on lisatud, kasuta seda konstruktsiooni:
            final DateFormat serverFormat = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US');

            final List<HistoricalPoint> points = [];

            for (var item in values) {
              try {
                // Puhastame stringi igaks juhuks .trim() abil
                final String dateStr = item['date'].toString().trim();
                
                // Parsime kuupäeva
                final DateTime dt = serverFormat.parse(dateStr);
                final double closePrice = (item['close'] as num?)?.toDouble() ?? 0.0;

                points.add(HistoricalPoint(
                  date: dt,
                  close: closePrice,
                ));
              } catch (e) {
                // Kui konkreetne rida ebaõnnestub, logime selle, aga jätkame teistega
                print("Viga konkreetse punkti parsimisel: ${item['date']} -> $e");
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

      return []; // Vea korral tagastame tühja listi
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
