import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static const String _dbName = 'deckwithcards4.db';
  static const int _dbVersion = 1;
  bool exists = false;

  DBHelper._();
  static final DBHelper _singleton = DBHelper._();
  factory DBHelper() => _singleton;

  Database? _database;

  Future<Database> get db async {
    if(_database != null) {
      return _database!;
    }
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    var dbDir = await getApplicationDocumentsDirectory();
    var dbPath = path.join(dbDir.path, _dbName);
    var db = await openDatabase(dbPath, version: _dbVersion, 
      onCreate: (Database db, int version) async {
        await db.execute(
          '''
            CREATE TABLE decks(
              id INTEGER PRIMARY KEY,
              title TEXT  
            ) 
          '''
        );

        await db.execute(
          '''
            CREATE TABLE flashcards(
              id INTEGER PRIMARY KEY,
              question TEXT,
              answer TEXT,
              deck_id INTEGER,
              FOREIGN KEY (deck_id) REFERENCES deck(id) 
            )
          '''
        );
      } 
    );
    return db;
  }

  Future<bool> dbExists() async {
    var dbDir = await getApplicationDocumentsDirectory();
    var dbPath = path.join(dbDir.path, _dbName);
    return await databaseExists(dbPath);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where}) async {
    final db = await this.db;
    return where == null ? db.query(table) : db.query(table, where: where);
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await this.db;
    int id = await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<void> update(String table, Map<String, dynamic> data) async {
    final db = await this.db;
    await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  }

  Future<void> deleteByID(String table, int deckID) async {
    final db = await this.db;
    await db.delete(
      table,
      where: 'deck_id = ?',
      whereArgs: [deckID],
    );
  }

  Future<void> delete(String table, int id) async {
    final db = await this.db;
    await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}