import 'package:buddy/services/db_helper.dart';

class TransactionRepository {
  final DatabaseHelper dbh = DatabaseHelper.instance;

  Future<int> add({
    required double amount,
    required String type,
    required DateTime date,
    String? note,
    required String category,
    required int iconCodePoint,
  }) async {
    final map = <String, Object?>{
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'note': note,
      'category': category,
      'icon': iconCodePoint,
    };
    return dbh.insertTransaction(map);
  }

  Future<int> update(int id, Map<String, Object?> values) async {
    return dbh.updateTransaction(id, values);
  }

  Future<int> delete(int id) async {
    return dbh.deleteTransaction(id);
  }

  Future<List<Map<String, Object?>>> getAll() async {
    return dbh.getAllTransactions();
  }

  Future<Map<String, Object?>?> getById(int id) async {
    return dbh.getTransactionById(id);
  }
}
