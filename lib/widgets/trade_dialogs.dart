import 'package:flutter/material.dart';
import '../providers/stock_provider.dart';

class TradeDialogs {
  static void showBuyDialog(
    BuildContext context,
    StockProvider stockProvider,
    String symbol,
    double price,
  ) {
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          final totalCost = quantity * price;
          final canAfford = stockProvider.balance >= totalCost;

          return AlertDialog(
            title: const Text('Buy Stock'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$symbol @ \$${price.toStringAsFixed(2)}/share'),
                const SizedBox(height: 12),
                const Divider(color: Colors.grey, thickness: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quantity:'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: quantity > 1
                              ? () => dialogSetState(() => quantity--)
                              : null,
                        ),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(
                              text: quantity.toString(),
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value) ?? 1;
                              if (parsed > 0) {
                                dialogSetState(() => quantity = parsed);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => dialogSetState(() => quantity++),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Cost:'),
                    Text(
                      '\$${totalCost.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: canAfford
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available:'),
                    Text(
                      '\$${stockProvider.balance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? Colors.green : Colors.grey[600],
                ),
                onPressed: canAfford
                    ? () {
                        stockProvider.buyStock(symbol, quantity);
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text('Buy'),
              ),
            ],
          );
        },
      ),
    );
  }

  static void showSellDialog(
    BuildContext context,
    StockProvider stockProvider,
    String symbol,
    double price,
    int owned,
  ) {
    if (owned == 0) return;

    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          final totalRevenue = quantity * price;

          return AlertDialog(
            title: const Text('Sell Stock'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$symbol @ \$${price.toStringAsFixed(2)}/share'),
                const SizedBox(height: 12),
                const Divider(color: Colors.grey, thickness: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quantity:'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: quantity > 1
                              ? () => dialogSetState(() => quantity--)
                              : null,
                        ),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(
                              text: quantity.toString(),
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value) ?? 1;
                              if (parsed > 0 && parsed <= owned) {
                                dialogSetState(() => quantity = parsed);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: quantity < owned
                              ? () => dialogSetState(() => quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Revenue:'),
                    Text(
                      '\$${totalRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('You own:'),
                    Text('$owned shares', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  stockProvider.sellStock(symbol, quantity);
                  Navigator.pop(context);
                },
                child: const Text('Sell'),
              ),
            ],
          );
        },
      ),
    );
  }
}
