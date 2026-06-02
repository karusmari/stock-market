import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../providers/auth_provider.dart';

class TradeDialogs {
  static void showBuyDialog(
    BuildContext context,
    StockProvider stockProvider,
    String symbol,
    double price,
  ) {
    int quantity = 1;
    final TextEditingController textController = TextEditingController(
      text: '1',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          final totalCost = quantity * price;
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final username = auth.currentUser ?? 'guest';
          final canAfford = stockProvider.balanceFor(username) >= totalCost;

          return AlertDialog(
            title: const Text('Buy Stock'),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8 > 400
                  ? 400
                  : MediaQuery.of(context).size.width * 0.8,
              child: Column(
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
                                ? () => dialogSetState(() {
                                    quantity--;
                                    textController.text = quantity.toString();
                                  })
                                : null,
                          ),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              controller: textController,
                              onChanged: (value) {
                                final parsed = int.tryParse(value) ?? 1;
                                if (parsed > 0) {
                                  quantity = parsed;
                                  dialogSetState(() {});
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => dialogSetState(() {
                              quantity++;
                              textController.text = quantity.toString();
                            }),
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
                              ? const Color.fromARGB(255, 83, 158, 77)
                              : const Color.fromARGB(255, 231, 114, 114),
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
                        '\$${stockProvider.balanceFor(username).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford
                      ? const Color.fromARGB(255, 83, 158, 77)
                      : Colors.grey[600],
                ),
                onPressed: canAfford
                    ? () async {
                        await stockProvider.buyStockFor(
                          username,
                          symbol,
                          quantity,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    : null,
                child: const Text('BUY', style: TextStyle(color: Colors.white)),
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
    final TextEditingController textController = TextEditingController(
      text: '1',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final username = auth.currentUser ?? 'guest';
          final totalRevenue = quantity * price;

          return AlertDialog(
            title: const Text('Sell Stock'),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8 > 400
                  ? 400
                  : MediaQuery.of(context).size.width * 0.8,
              child: Column(
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
                                ? () => dialogSetState(() {
                                    quantity--;
                                    textController.text = quantity.toString();
                                  })
                                : null,
                          ),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              controller: textController,
                              onChanged: (value) {
                                final parsed = int.tryParse(value) ?? 1;
                                final clamped = parsed.clamp(1, owned);
                                if (clamped != quantity) {
                                  dialogSetState(() {
                                    quantity = clamped;
                                    textController.text = quantity.toString();
                                  });
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: quantity < owned
                                ? () => dialogSetState(() {
                                    quantity++;
                                    textController.text = quantity.toString();
                                  })
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
                          color: const Color.fromARGB(255, 83, 158, 77),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('You own:'),
                      Text(
                        '$owned shares',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 231, 114, 114),
                ),
                onPressed: () async {
                  await stockProvider.sellStockFor(username, symbol, quantity);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
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
