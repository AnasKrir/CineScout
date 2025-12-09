import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static const _dbName = 'cinescout.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table Watchlist
    await db.execute('''
      CREATE TABLE watchlist(
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        posterPath TEXT,
        overview TEXT,
        voteAverage REAL,
        type TEXT NOT NULL,
        addedAt TEXT NOT NULL
      );
    ''');

    // Table Cache des pages
    await db.execute('''
      CREATE TABLE cached_pages(
        key TEXT PRIMARY KEY,
        json TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      );
    ''');
  }
}
