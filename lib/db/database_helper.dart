import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';

class DatabaseHelper {
  static const _databaseName = "inventory.db";
  static const _databaseVersion = 1;

  static const table = 'items';

  static const columnId = 'id';
  static const columnName = 'name';
  static const columnPrice = 'price';
  static const columnStock = 'stock'; // Initial stock
  static const columnSold = 'sold'; // Sold items
  static const columnImage = 'image'; // Image path
  static const columnTimestamp = 'timestamp'; // Timestamp

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // Set up logging
  static final Logger _logger = Logger('DatabaseHelper');

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      return await openDatabase(
        join(await getDatabasesPath(), _databaseName),
        onCreate: (db, version) {
          return db.execute('''
            CREATE TABLE $table (
              $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
              $columnName TEXT NOT NULL,
              $columnPrice REAL NOT NULL,
              $columnStock INTEGER NOT NULL,  -- Initial stock
              $columnSold INTEGER NOT NULL DEFAULT 0,  -- Sold items
              $columnImage TEXT,  -- Image path
              $columnTimestamp INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))  -- Unix timestamp
            )
          ''');
        },
        version: _databaseVersion,
      );
    } catch (e) {
      _logger.severe('Error initializing database: $e');
      rethrow;
    }
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    try {
      return await db.insert(table, row);
    } catch (e) {
      _logger.severe('Error inserting data: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryAll() async {
    Database db = await instance.database;
    try {
      return await db.query(table, orderBy: '$columnTimestamp DESC');
    } catch (e) {
      _logger.severe('Error querying data: $e');
      rethrow;
    }
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    try {
      return await db
          .update(table, row, where: '$columnId = ?', whereArgs: [id]);
    } catch (e) {
      _logger.severe('Error updating data: $e');
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    try {
      return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
    } catch (e) {
      _logger.severe('Error deleting data: $e');
      rethrow;
    }
  }


  Future<Map<String, dynamic>> getDailySummary() async {
  Database db = await instance.database;
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch ~/ 1000;
  final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).millisecondsSinceEpoch ~/ 1000;

  final result = await db.rawQuery('''
      SELECT 
        SUM($columnStock) as totalStock, 
        SUM($columnSold) as totalSold, 
        AVG($columnPrice) as avgPrice
      FROM $table
      WHERE $columnTimestamp BETWEEN ? AND ?
    ''', [startOfDay, endOfDay]);

  return result.isNotEmpty ? result.first : {};
  }

  Future<Map<String, dynamic>> getWeeklySummary() async {
  Database db = await instance.database;
  final today = DateTime.now();
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  final startOfWeekMillis = startOfWeek.millisecondsSinceEpoch ~/ 1000;
  final endOfWeekMillis = today.add(Duration(days: 7 - today.weekday)).millisecondsSinceEpoch ~/ 1000;

  final result = await db.rawQuery('''
      SELECT 
        SUM($columnStock) as totalStock, 
        SUM($columnSold) as totalSold, 
        AVG($columnPrice) as avgPrice
      FROM $table
      WHERE $columnTimestamp BETWEEN ? AND ?
    ''', [startOfWeekMillis, endOfWeekMillis]);

  return result.isNotEmpty ? result.first : {};
  }

  Future<Map<String, dynamic>> getMonthlySummary() async {
  Database db = await instance.database;
  final today = DateTime.now();
  final startOfMonth = DateTime(today.year, today.month, 1);
  final startOfMonthMillis = startOfMonth.millisecondsSinceEpoch ~/ 1000;
  final endOfMonthMillis = DateTime(today.year, today.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch ~/ 1000;

  final result = await db.rawQuery('''
      SELECT 
        SUM($columnStock) as totalStock, 
        SUM($columnSold) as totalSold, 
        AVG($columnPrice) as avgPrice
      FROM $table
      WHERE $columnTimestamp BETWEEN ? AND ?
    ''', [startOfMonthMillis, endOfMonthMillis]);

  return result.isNotEmpty ? result.first : {};
  }

  Future<Map<String, dynamic>> getMostSoldItem() async {
  Database db = await instance.database;
  final result = await db.rawQuery('''
      SELECT 
        $columnName, 
        SUM($columnSold) as totalSold
      FROM $table
      GROUP BY $columnName
      ORDER BY totalSold DESC
      LIMIT 1
    ''');

  return result.isNotEmpty ? result.first : {};
  }

  Future<Map<String, dynamic>> getLeastSoldItem() async {
  Database db = await instance.database;
  final result = await db.rawQuery('''
      SELECT 
        $columnName, 
        SUM($columnSold) as totalSold
      FROM $table
      GROUP BY $columnName
      ORDER BY totalSold ASC
      LIMIT 1
    ''');

  return result.isNotEmpty ? result.first : {};
  }

  Future<Map<String, dynamic>> getMediumSoldItem() async {
  Database db = await instance.database;
  final result = await db.rawQuery('''
      SELECT 
        $columnName, 
        SUM($columnSold) as totalSold
      FROM $table
      GROUP BY $columnName
      ORDER BY ABS(totalSold - (SELECT AVG(totalSold) FROM (
        SELECT SUM($columnSold) as totalSold
        FROM $table
        GROUP BY $columnName
      ))) 
      LIMIT 1
    ''');

  return result.isNotEmpty ? result.first : {};
  }
}


