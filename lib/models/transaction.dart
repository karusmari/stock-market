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
  final int typeId = 1; // Unique ID for this adapter (must be different from other adapters)

  @override
  // when asking for the transaction object from storage, we read the binary data and convert it back to a Transaction object
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
  // writing the transaction object to binary format for storage in Hive
  void write(BinaryWriter writer, Transaction obj) { 
    writer.writeString(obj.symbol);
    writer.writeInt(obj.quantity);
    writer.writeDouble(obj.price);
    writer.writeString(obj.type);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
  }
}

// Hive accepts only primitive types and lists/maps of primitive types (string, int, double, bool), 
// so we need to convert our Transaction objects to a storable format (like a Map) 
// when saving, and convert them back when loading. 
// This is handled in the StockProvider when we save/load user data.
