import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;
  bool _isInitialized = false;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    await initdb();
    return _database!;
  }

  Future<void> initdb() async {
    if (_isInitialized && _database != null && _database!.isOpen) {
      return;
    }

    try {
      final dbPath = join(await getDatabasesPath(), 'user.db');

      _database = await openDatabase(
        dbPath,
        version: 1,
        readOnly: false, // Ensure database is writable
        singleInstance: true,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing database: $e');
      _isInitialized = false;
      _database = null;
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE transactions('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'amount REAL NOT NULL,'
      'type TEXT NOT NULL,'
      'date TEXT NOT NULL,'
      'note TEXT,'
      'category TEXT NOT NULL,'
      'icon INTEGER NOT NULL'
      ')',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  // Transaction-specific helpers matching your previous style
  Future<int> insertTransaction(Map<String, Object?> values) async {
    debugPrint('💾 DATABASE: Inserting transaction: ${values['type']} ₹${values['amount']} on ${values['date']}');
    final db = await database;
    final id = await db.insert(
      'transactions',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('✅ DATABASE: Transaction saved with ID: $id');
    return id;
  }

  Future<int> updateTransaction(int id, Map<String, Object?> values) async {
    final db = await database;
    return db.update(
      'transactions',
      values,
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getAllTransactions() async {
    final db = await database;
    final results = await db.query('transactions', orderBy: 'date DESC');
    debugPrint('📖 DATABASE: Retrieved ${results.length} transactions');
    for (final row in results) {
      debugPrint('   - ${row['type']} ₹${row['amount']} (${row['category']}) [ID: ${row['id']}]');
    }
    return results;
  }

  Future<Map<String, Object?>?> getTransactionById(int id) async {
    final db = await database;
    final res = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
    }
  }
}
