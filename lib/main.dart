import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/stock_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/stock_detail_screen.dart';
import 'models/transaction.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized before any async operations (it is required for Hive initialization)
  await Hive.initFlutter(); // Initialize Hive for Flutter
  Hive.registerAdapter(TransactionAdapter()); // Register the Transaction adapter for more complicated data storage
  await Hive.openBox('users'); // Open a box for user data (balances, portfolios, transactions)

  runApp(
    MultiProvider( // Using MultiProvider to provide both AuthProvider and StockProvider to the widget tree
      providers: [
        ChangeNotifierProvider(create: (_) {
          final auth = AuthProvider();
          auth.restoreSession(); // checking for existing session on app start
          return auth;
        }),
        ChangeNotifierProvider(create: (_) => StockProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stock Simulator',
      theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/stocks': (context) => const HomeScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/stock_detail': (context) {
          final symbol = ModalRoute.of(context)?.settings.arguments as String?;
          return StockDetailScreen(symbol: symbol ?? 'AAPL');
        },
      },
    );
  }
}
