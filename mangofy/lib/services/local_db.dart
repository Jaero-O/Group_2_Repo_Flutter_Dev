import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/scan_item.dart';

class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pi_sync.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pi_scans(
            id INTEGER PRIMARY KEY,
            title TEXT,
            description TEXT,
            timestamp TEXT,
            image_path TEXT,
            image_url TEXT,
            checksum TEXT,
            source TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
  }

  Future<void> upsertScan(ScanItem item) async {
    final db = await database;
    await db.insert(
      'pi_scans',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScanItem>> getAllScans() async {
    final db = await database;
    final rows = await db.query('pi_scans', orderBy: 'timestamp DESC');
    return rows.map((row) => ScanItem.fromJson(row)).toList();
  }

  Future<ScanItem?> getScanById(int id) async {
    final db = await database;
    final rows = await db.query('pi_scans', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ScanItem.fromJson(rows.first);
  }

  Future<void> deleteScan(int id) async {
    final db = await database;
    await db.delete('pi_scans', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllScans() async {
    final db = await database;
    await db.delete('pi_scans');
  }
}
