import 'package:hive/hive.dart';

// We'll implement a manual TypeAdapter below instead of using build_runner.
class Transaction {
  final String symbol;
  final int quantity;
  final double price;
  final String type; // 'buy' or 'sell'
  final DateTime timestamp;

  Transaction({
    required this.symbol,
    required this.quantity,
    required this.price,
    required this.type,
    required this.timestamp,
  });
}

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 1;

  @override
  Transaction read(BinaryReader reader) {
    final symbol = reader.readString();
    final quantity = reader.readInt();
    final price = reader.readDouble();
    final type = reader.readString();
    final timestamp = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    return Transaction(
      symbol: symbol,
      quantity: quantity,
      price: price,
      type: type,
      timestamp: timestamp,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer.writeString(obj.symbol);
    writer.writeInt(obj.quantity);
    writer.writeDouble(obj.price);
    writer.writeString(obj.type);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
  }
}
