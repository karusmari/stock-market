import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/stock_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/historical_point.dart';
import '../widgets/trade_dialogs.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  const StockDetailScreen({super.key, required this.symbol});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  List<HistoricalPoint> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await ApiService().fetchStockHistory(widget.symbol, days: 180);
      if (mounted) {
        setState(() {
          history = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    final currentStock = stockProvider.stocks[widget.symbol];
    final currentPrice = currentStock?.price ?? 0.0;
    final auth = Provider.of<AuthProvider>(context);
    final username = auth.currentUser ?? 'guest';
    final ownedQuantity = stockProvider.portfolioFor(username)[widget.symbol] ?? 0;

    final closes = history.isNotEmpty ? history.map((e) => e.close).toList() : <double>[];
    double lowestPrice = closes.isNotEmpty ? closes.reduce((a, b) => a < b ? a : b) : currentPrice;
    double highestPrice = closes.isNotEmpty ? closes.reduce((a, b) => a > b ? a : b) : currentPrice;
    double priceChange = closes.isNotEmpty ? currentPrice - closes.first : 0.0;
    double percentageChange = closes.isNotEmpty && closes.first != 0 ? (priceChange / closes.first) * 100 : 0.0;
    Color changeColor = priceChange >= 0 ? Colors.greenAccent : Colors.redAccent;

    double minYVal = lowestPrice * 0.98;
    double maxYVal = highestPrice * 1.02;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.symbol} Detailid')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text('\$${currentPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${priceChange >= 0 ? '+' : ''}\$${priceChange.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 18, color: changeColor, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Text('(${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(2)}%)',
                          style: TextStyle(fontSize: 18, color: changeColor)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Graafiku info kast
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          const Text('6-Month Chart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoCol('High', '\$${highestPrice.toStringAsFixed(2)}', Colors.greenAccent),
                              _buildInfoCol('Low', '\$${lowestPrice.toStringAsFixed(2)}', Colors.redAccent),
                              _buildInfoCol('Range', '\$${(highestPrice - lowestPrice).toStringAsFixed(2)}', Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // GRAAFIK
                  SizedBox(
                    height: 320,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: history.isEmpty
                          ? const Center(child: Text('No historical data available'))
                          : LineChart(
                              LineChartData(
                                minY: minYVal,
                                maxY: maxYVal,
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      interval: (history.length > 30 ? history.length / 5 : 5).toDouble(),
                                      getTitlesWidget: (value, meta) {
                                        int idx = value.toInt();
                                        if (idx < 0 || idx >= history.length) return const SizedBox.shrink();
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 8,
                                          child: Text(DateFormat('MMM').format(history[idx].date),
                                              style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.close)).toList(),
                                    isCurved: true,
                                    color: Colors.blueAccent,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.1)),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  
                  // Omadused (Holdings)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Your Holdings:'),
                          Text('$ownedQuantity shares', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // NUPUD
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: ownedQuantity > 0 ? Colors.red : Colors.grey[600]),
                            onPressed: ownedQuantity > 0 ? () => TradeDialogs.showSellDialog(context, stockProvider, widget.symbol, currentPrice, ownedQuantity) : null,
                            child: const Text('SELL', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () => TradeDialogs.showBuyDialog(context, stockProvider, widget.symbol, currentPrice),
                            child: const Text('BUY', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCol(String label, String value, Color valColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valColor)),
      ],
    );
  }
}