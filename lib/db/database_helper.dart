import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';

class DatabaseHelper {
  static const _databaseName = "inventory.db";
  static const _databaseVersion = 2; // Incremented version for schema change

  static const table = 'items';

  static const columnId = 'id';
  static const columnName = 'name';
  static const columnBuyingPrice = 'buyingPrice'; // New column
  static const columnSellingPrice = 'sellingPrice'; // New column
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
        version: _databaseVersion,
        onCreate: (db, version) async {
          try {
            await db.execute('''
              CREATE TABLE $table (
                $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
                $columnName TEXT NOT NULL,
                $columnBuyingPrice REAL NOT NULL,
                $columnSellingPrice REAL NOT NULL,
                $columnStock INTEGER NOT NULL,
                $columnSold INTEGER NOT NULL DEFAULT 0,
                $columnImage TEXT,
                $columnTimestamp INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
              )
            ''');
            _logger.info('Table $table created successfully.');
          } catch (e) {
            _logger.severe('Error creating table: $e');
            rethrow;
          }
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            try {
              await db.execute('''
                ALTER TABLE $table ADD COLUMN $columnBuyingPrice REAL NOT NULL DEFAULT 0;
              ''');
              await db.execute('''
                ALTER TABLE $table ADD COLUMN $columnSellingPrice REAL NOT NULL DEFAULT 0;
              ''');
              _logger.info('Database upgraded to version $newVersion: Added new columns.');
            } catch (e) {
              _logger.severe('Error upgrading database: $e');
              rethrow;
            }
          }
          // Future migrations can be handled here by checking the version
        },
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

  // Method to retrieve an item by its name
  Future<Map<String, dynamic>?> getItemByName(String name) async {
    Database db = await instance.database;
    try {
      List<Map<String, dynamic>> result = await db.query(
        table,
        where: '$columnName = ?',
        whereArgs: [name],
      );
      if (result.isNotEmpty) {
        return result.first;
      } else {
        return null;
      }
    } catch (e) {
      _logger.severe('Error retrieving item by name: $e');
      rethrow;
    }
  }
}
