import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/stock_provider.dart';
import '../widgets/trade_dialogs.dart';
import 'stock_detail_screen.dart';
import 'wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Market Simulator'),
        centerTitle: true,
      ),
      body: _currentTabIndex == 0 ? _buildStocksView() : const WalletScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Stocks',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
        ],
      ),
    );
  }

  Widget _buildStocksView() {
    return Consumer<StockProvider>(
      builder: (context, stockProvider, child) {
        final stockList = stockProvider.stocks.values.toList();

        if (stockList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: stockList.length,
          itemBuilder: (context, index) {
            final stock = stockList[index];
            final double currentPrice = stock.price;
            final double previousPrice =
                stockProvider.previousPrices[stock.symbol] ?? currentPrice;
            final int ownedQuantity =
                stockProvider.portfolio[stock.symbol] ?? 0;

            Color priceColor = Colors.white;
            IconData trendIcon = Icons.remove;
            if (currentPrice > previousPrice) {
              priceColor = Colors.greenAccent;
              trendIcon = Icons.trending_up;
            } else if (currentPrice < previousPrice) {
              priceColor = Colors.redAccent;
              trendIcon = Icons.trending_down;
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        StockDetailScreen(symbol: stock.symbol),
                  ),
                );
              },
              child: Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock.symbol,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(trendIcon, color: priceColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                ownedQuantity > 0
                                    ? '$ownedQuantity shares'
                                    : 'Not owned',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ownedQuantity > 0
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${currentPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: priceColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: ownedQuantity > 0
                                    ? () => TradeDialogs.showSellDialog(
                                        context,
                                        stockProvider,
                                        stock.symbol,
                                        currentPrice,
                                        ownedQuantity,
                                      )
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ownedQuantity > 0
                                        ? Colors.redAccent
                                        : Colors.grey[700],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'SELL',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: ownedQuantity > 0
                                          ? Colors.white
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => TradeDialogs.showBuyDialog(
                                  context,
                                  stockProvider,
                                  stock.symbol,
                                  currentPrice,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'BUY',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
