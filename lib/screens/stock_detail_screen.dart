import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/stock_provider.dart';
import '../services/api_service.dart';
import '../widgets/trade_dialogs.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  const StockDetailScreen({super.key, required this.symbol});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  List<double> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    print(
      'KÜSIN AJALUGU AADRESSILT: ${ApiService.baseUrl}/hist/${widget.symbol}',
    );
    final data = await ApiService().fetchStockHistory(widget.symbol);
    print('Loaded history for ${widget.symbol}: $data');
    setState(() {
      history = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    final currentStock = stockProvider.stocks[widget.symbol];
    final currentPrice = currentStock?.price ?? 0.0;
    final ownedQuantity = stockProvider.portfolio[widget.symbol] ?? 0;

    double lowestPrice = history.isNotEmpty
        ? history.reduce((a, b) => a < b ? a : b)
        : currentPrice;
    double highestPrice = history.isNotEmpty
        ? history.reduce((a, b) => a > b ? a : b)
        : currentPrice;
    double priceChange = history.isNotEmpty
        ? currentPrice - history.first
        : 0.0;
    double percentageChange = history.isNotEmpty && history.first != 0
        ? (priceChange / history.first) * 100
        : 0.0;
    Color changeColor = priceChange >= 0
        ? Colors.greenAccent
        : Colors.redAccent;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.symbol} Detailid')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    '\$${currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${priceChange >= 0 ? '+' : ''}\$${priceChange.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          color: changeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '(${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(2)}%)',
                        style: TextStyle(fontSize: 18, color: changeColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '30-Day Chart',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${DateFormat('MMM dd, yyyy').format(DateTime.now().subtract(const Duration(days: 30)))} - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'High',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '\$${highestPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Low',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '\$${lowestPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Range',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '\$${(highestPrice - lowestPrice).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LineChart(
                        LineChartData(
                          minY: lowestPrice * 0.98,
                          maxY: highestPrice * 1.02,
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: history.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value);
                              }).toList(),
                              isCurved: true,
                              color: Colors.blueAccent,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blueAccent.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Your Holdings:'),
                          Text(
                            '$ownedQuantity shares',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ownedQuantity > 0
                                  ? Colors.red
                                  : Colors.grey[600],
                              disabledBackgroundColor: Colors.grey[600],
                            ),
                            onPressed: ownedQuantity > 0
                                ? () => TradeDialogs.showSellDialog(
                                    context,
                                    stockProvider,
                                    widget.symbol,
                                    currentPrice,
                                    ownedQuantity,
                                  )
                                : null,
                            child: Text(
                              'SELL',
                              style: TextStyle(
                                color: ownedQuantity > 0
                                    ? Colors.white
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () => TradeDialogs.showBuyDialog(
                              context,
                              stockProvider,
                              widget.symbol,
                              currentPrice,
                            ),
                            child: const Text('BUY'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }
}
