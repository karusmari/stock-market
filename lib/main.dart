import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/stock_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    // MultiProvider võimaldab meil hiljem lisada ka AuthProvideri (autentimine)
    MultiProvider(
      providers: [
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
      theme: ThemeData(
        brightness: Brightness.dark, // Börsiäpid näevad tumedana head välja
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}