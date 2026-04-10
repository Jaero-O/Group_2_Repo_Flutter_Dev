import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/scan_item.dart';
import '../model/scan_summary_model.dart';

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
      version: 2,
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
            updated_at TEXT,
            disease TEXT,
            confidence REAL,
            severity_value REAL,
            photo_id INTEGER,
            scan_dir TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add new columns for RasPi scan payload + gallery linkage.
          await db.execute('ALTER TABLE pi_scans ADD COLUMN disease TEXT');
          await db.execute('ALTER TABLE pi_scans ADD COLUMN confidence REAL');
          await db.execute('ALTER TABLE pi_scans ADD COLUMN severity_value REAL');
          await db.execute('ALTER TABLE pi_scans ADD COLUMN photo_id INTEGER');
          await db.execute('ALTER TABLE pi_scans ADD COLUMN scan_dir TEXT');
        }
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

  Future<void> setScanPhotoId(int scanId, int photoId) async {
    final db = await database;
    await db.update(
      'pi_scans',
      {'photo_id': photoId},
      where: 'id = ?',
      whereArgs: [scanId],
    );
  }

  Future<ScanSummary> getScanSummary() async {
    final db = await database;
    final rows = await db.query('pi_scans');

    int total = rows.length;
    int healthy = 0;
    int moderate = 0;
    int severe = 0;

    for (final row in rows) {
      final severity = (row['severity_value'] is num)
          ? (row['severity_value'] as num).toDouble()
          : double.tryParse(row['severity_value']?.toString() ?? '') ?? 0.0;

      if (severity > 40.0) {
        severe++;
      } else if (severity > 5.0) {
        moderate++;
      } else {
        healthy++;
      }
    }

    return ScanSummary(
      totalScans: total,
      healthyCount: healthy,
      moderateCount: moderate,
      severeCount: severe,
    );
  }

  Future<List<Map<String, dynamic>>> getDiseaseDistribution() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(NULLIF(TRIM(disease), ''), 'Unknown') AS disease,
        COUNT(*) AS count
      FROM pi_scans
      GROUP BY disease
      ORDER BY count DESC
    ''');
    return rows;
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
