import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;
  bool _isInitialized = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initdb();
    return _database!;
  }

  Future<void> initdb() async {
    if (_isInitialized) return;
    _database = await openDatabase(
      join(await getDatabasesPath(), 'user.db'),
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _isInitialized = true;
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
    final db = await database;
    return db.insert(
      'transactions',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    return db.query('transactions', orderBy: 'date DESC');
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
