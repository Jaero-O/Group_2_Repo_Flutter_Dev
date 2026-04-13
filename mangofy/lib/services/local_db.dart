import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../model/scan_item.dart';
import '../model/scan_summary_model.dart';
import '../model/dataset_folder_model.dart';

class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();
  static const String _legacyDataMigrationFlag = 'legacy_local_db_data_migrated_v1';

  Database? _db;

  Future<String> get dbFilePath async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'pi_sync.db');
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = await dbFilePath;

    final db = await openDatabase(
      path,
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // Create tbl_tree
        await db.execute('''
          CREATE TABLE tbl_tree(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            location TEXT,
            variety TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Create tbl_disease
        await db.execute('''
          CREATE TABLE tbl_disease(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            description TEXT,
            symptoms TEXT,
            prevention TEXT
          )
        ''');

        // Create tbl_severity_level
        await db.execute('''
          CREATE TABLE tbl_severity_level(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            description TEXT
          )
        ''');

        // Create tbl_scan_record
        await db.execute('''
          CREATE TABLE tbl_scan_record(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tree_id INTEGER REFERENCES tbl_tree(id) ON DELETE CASCADE,
            disease_id INTEGER REFERENCES tbl_disease(id) ON DELETE SET NULL,
            severity_level_id INTEGER REFERENCES tbl_severity_level(id) ON DELETE SET NULL,
            scan_timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
            scan_duration REAL,
            scan_status TEXT,
            disease_class TEXT,
            confidence_score REAL,
            pred_anthracnose REAL,
            pred_healthy REAL,
            pred_bacterial_canker REAL,
            pred_cutting_weevil REAL,
            pred_powdery_mildew REAL,
            pred_sooty_mould REAL,
            severity_percentage REAL,
            severity_level TEXT,
            leaf_area_cm2 REAL,
            lesion_area_cm2 REAL,
            lesion_count INTEGER,
            mean_lesion_size_px REAL,
            leaf_mean_r REAL,
            leaf_mean_g REAL,
            leaf_mean_b REAL,
            lesion_mean_r REAL,
            lesion_mean_g REAL,
            lesion_mean_b REAL,
            lesion_to_leaf_color_ratio_g REAL,
            exg_mean REAL,
            ndvi_proxy_mean REAL,
            leaf_solidity REAL,
            leaf_circularity REAL,
            leaf_aspect_ratio REAL,
            damage_pct_inpaint REAL,
            lesion_glcm_contrast REAL,
            lesion_glcm_dissimilarity REAL,
            lesion_glcm_energy REAL,
            lesion_glcm_homogeneity REAL,
            lesion_glcm_correlation REAL,
            image_path TEXT,
            thumbnail_path TEXT,
            json_path TEXT,
            notes TEXT,
            is_archived INTEGER DEFAULT 0,
            total_leaf_area REAL,
            lesion_area REAL,
            source TEXT,
            analysis_status TEXT,
            analysis_error TEXT,
            analysis_updated_at TEXT
          )
        ''');

        // Create tbl_photos
        await db.execute('''
          CREATE TABLE tbl_photos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            data TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            path TEXT,
            title TEXT,
            description TEXT,
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

        // Create tbl_my_trees
        await db.execute('''
          CREATE TABLE tbl_my_trees(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL UNIQUE,
            location TEXT,
            images TEXT,
            cover_image TEXT
          )
        ''');

        // Create tbl_dataset_folders
        await db.execute('''
          CREATE TABLE tbl_dataset_folders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            images TEXT NOT NULL,
            date_created TEXT NOT NULL
          )
        ''');

        // Create indexes
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_tree_name ON tbl_tree(name)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_record_disease ON tbl_scan_record(disease_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_record_severity ON tbl_scan_record(severity_level_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_record_tree ON tbl_scan_record(tree_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_scan_archived ON tbl_scan_record(is_archived)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_scan_archived_timestamp ON tbl_scan_record(is_archived, scan_timestamp DESC)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_scan_record_timestamp ON tbl_scan_record(scan_timestamp)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_scan_tree_archived ON tbl_scan_record(tree_id, is_archived)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_photos_photo_id ON tbl_photos(photo_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_photos_name_timestamp ON tbl_photos(name, timestamp)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Legacy migration removed: current schema uses tbl_* tables.
        }
        // Removed migration to version 3 to eliminate pi_scans references
        if (oldVersion < 4) {
          // Add photos table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tbl_photos(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              data TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              path TEXT,
              title TEXT,
              description TEXT,
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
          // Add my_trees table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tbl_my_trees(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL UNIQUE,
              location TEXT,
              images TEXT,
              cover_image TEXT
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tbl_dataset_folders(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              images TEXT NOT NULL,
              date_created TEXT NOT NULL
            )
          ''');
        }
      },
    );

    // Ensure import/read-path indexes exist even on upgraded databases.
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_photos_photo_id ON tbl_photos(photo_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_photos_name_timestamp ON tbl_photos(name, timestamp)',
    );

    await _migrateLegacyLocalData(db);
    return db;
  }

  Future<void> _migrateLegacyLocalData(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_legacyDataMigrationFlag) == true) {
        return;
      }

      final dbPath = await getDatabasesPath();
      final legacyPath = join(dbPath, 'mangofy.db');
      final legacyFile = File(legacyPath);
      if (!await legacyFile.exists()) {
        await prefs.setBool(_legacyDataMigrationFlag, true);
        return;
      }

      final legacyDb = await openDatabase(legacyPath, readOnly: true);
      try {
        final datasetTable = await legacyDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='dataset_folders' LIMIT 1",
        );
        if (datasetTable.isNotEmpty) {
          final rows = await legacyDb.query('dataset_folders');
          for (final row in rows) {
            final name = (row['name']?.toString() ?? '').trim();
            if (name.isEmpty) continue;
            await db.insert('tbl_dataset_folders', {
              'name': name,
              'images': row['images']?.toString() ?? '',
              'date_created':
                  row['date_created']?.toString() ??
                  DateTime.now().toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }

        final treesTable = await legacyDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='my_trees' LIMIT 1",
        );
        if (treesTable.isNotEmpty) {
          final rows = await legacyDb.query('my_trees');
          for (final row in rows) {
            final title = (row['title']?.toString() ?? '').trim();
            if (title.isEmpty) continue;
            await db.insert('tbl_my_trees', {
              'title': title,
              'location': row['location']?.toString() ?? '',
              'images': row['images']?.toString() ?? '',
              'cover_image': row['cover_image']?.toString() ?? 'images/leaf.png',
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      } finally {
        await legacyDb.close();
      }

      await prefs.setBool(_legacyDataMigrationFlag, true);
    } catch (_) {
      // Best-effort migration; keep app startup resilient.
    }
  }

  Future<void> replaceDatabaseFromFile(
    String sourcePath, {
    bool keepBackup = true,
  }) async {
    final destPath = await dbFilePath;
    final destFile = File(destPath);
    final srcFile = File(sourcePath);
    if (!await srcFile.exists()) {
      throw Exception('Downloaded DB not found at $sourcePath');
    }

    await close();

    final backupPath = '$destPath.bak';
    if (keepBackup && await destFile.exists()) {
      await destFile.copy(backupPath);
    }

    final tmpPath = '$destPath.tmp';
    final tmpFile = File(tmpPath);
    if (await tmpFile.exists()) await tmpFile.delete();
    await srcFile.copy(tmpPath);

    if (await destFile.exists()) {
      await destFile.delete();
    }
    await tmpFile.rename(destPath);

    // Sanity check: ensure expected tables and columns exist.
    try {
      final db = await openDatabase(destPath, readOnly: true);
      try {
        // Check required tables
        final requiredTables = [
          'tbl_tree',
          'tbl_disease',
          'tbl_severity_level',
          'tbl_scan_record',
        ];
        for (final table in requiredTables) {
          final rows = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
            [table],
          );
          if (rows.isEmpty) {
            throw Exception('Imported DB missing required table: $table');
          }
        }

        // Check essential columns in tbl_scan_record
        final scanColumns = await db.rawQuery(
          "PRAGMA table_info(tbl_scan_record)",
        );
        final columnNames = scanColumns
            .map((row) => row['name'] as String)
            .toSet();
        final requiredScanColumns = {
          'id',
          'scan_timestamp',
          'disease_class',
          'image_path',
          'tree_id',
          'disease_id',
          'severity_level_id',
          'confidence_score',
          'severity_percentage',
          'is_archived',
        };
        if (!requiredScanColumns.every(columnNames.contains)) {
          throw Exception(
            'Imported DB tbl_scan_record missing essential columns: ${requiredScanColumns.where((c) => !columnNames.contains(c)).join(', ')}',
          );
        }
      } finally {
        await db.close();
      }
    } catch (e) {
      // Roll back to backup if the new DB cannot be opened/validated.
      if (keepBackup && await File(backupPath).exists()) {
        if (await destFile.exists()) await destFile.delete();
        await File(backupPath).copy(destPath);
      }
      rethrow;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  String _resolvedDiseaseName(ScanItem item) {
    if (item.diseaseName.trim().isNotEmpty) return item.diseaseName.trim();
    if (item.disease.trim().isNotEmpty) return item.disease.trim();
    if (item.title.trim().isNotEmpty) return item.title.trim();
    return '';
  }

  String _resolvedSeverityName(ScanItem item) {
    if (item.severityLevelName.trim().isNotEmpty) {
      return item.severityLevelName.trim();
    }

    final disease = _resolvedDiseaseName(item).toLowerCase();
    if (disease == 'healthy') return 'Healthy';
    if (item.severityValue > 40.0) return 'Advanced Stage';
    if (item.severityValue > 5.0) return 'Early Stage';
    return 'Healthy';
  }

  Future<void> upsertScan(ScanItem item) async {
    final db = await database;

    // Upsert tree if data provided
    int? treeId = item.treeId;
    if (treeId != null && item.treeName.isNotEmpty) {
      await db.insert('tbl_tree', {
        'id': treeId,
        'name': item.treeName,
        'location': item.treeLocation,
        'variety': item.treeVariety,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Upsert disease if data provided
    int? diseaseId = item.diseaseId;
    if (diseaseId != null && item.diseaseName.isNotEmpty) {
      await db.insert('tbl_disease', {
        'id': diseaseId,
        'name': item.diseaseName,
        'description': item.diseaseDescription,
        'symptoms': item.diseaseSymptoms,
        'prevention': item.diseasePrevention,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Upsert severity level if data provided
    int? severityLevelId = item.severityLevelId;
    if (severityLevelId != null && item.severityLevelName.isNotEmpty) {
      await db.insert('tbl_severity_level', {
        'id': severityLevelId,
        'name': item.severityLevelName,
        'description': item.severityLevelDescription,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Fallback to old logic if IDs not provided
    if (treeId == null && item.treeName.isNotEmpty) {
      final treeRows = await db.query(
        'tbl_tree',
        where: 'name = ?',
        whereArgs: [item.treeName],
      );
      if (treeRows.isEmpty) {
        treeId = await db.insert('tbl_tree', {
          'name': item.treeName,
          'location': item.treeLocation,
          'variety': item.treeVariety,
        });
      } else {
        treeId = treeRows.first['id'] as int;
      }
    }

    final diseaseName = _resolvedDiseaseName(item);
    if (diseaseId == null && diseaseName.isNotEmpty) {
      final diseaseRows = await db.query(
        'tbl_disease',
        where: 'name = ?',
        whereArgs: [diseaseName],
      );
      if (diseaseRows.isEmpty) {
        diseaseId = await db.insert('tbl_disease', {'name': diseaseName});
      } else {
        diseaseId = diseaseRows.first['id'] as int;
      }
    }

    final resolvedSeverityName = _resolvedSeverityName(item);
    if (severityLevelId == null) {
      final severityRows = await db.query(
        'tbl_severity_level',
        where: 'name = ?',
        whereArgs: [resolvedSeverityName],
      );
      if (severityRows.isEmpty) {
        severityLevelId = await db.insert('tbl_severity_level', {
          'name': resolvedSeverityName,
        });
      } else {
        severityLevelId = severityRows.first['id'] as int;
      }
    }

    await db.insert('tbl_scan_record', {
      'id': item.id,
      'tree_id': treeId,
      'disease_id': diseaseId,
      'severity_level_id': severityLevelId,
      'scan_timestamp': item.timestamp,
      'disease_class': diseaseName,
      'confidence_score': item.confidence,
      'severity_percentage': item.severityValue,
      'severity_level': resolvedSeverityName,
      'image_path': item.imagePath,
      'source': item.source,
      'analysis_updated_at': item.updatedAt,
      'is_archived': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ScanItem>> getAllScans() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT r.*, t.name as tree_name, t.location as tree_location, t.variety as tree_variety,
             d.name as disease_name, d.description as disease_description, d.symptoms as disease_symptoms, d.prevention as disease_prevention,
            s.name as severity_name, s.description as severity_description,
        COALESCE(NULLIF(TRIM(d.name), ''), NULLIF(TRIM(r.disease_class), ''), '') as resolved_disease,
            COALESCE(NULLIF(TRIM(r.severity_level), ''), NULLIF(TRIM(s.name), ''), '') as resolved_severity_name,
            COALESCE(
              NULLIF(TRIM(r.image_path), ''),
              NULLIF(TRIM(r.thumbnail_path), ''),
              NULLIF(TRIM((
                SELECT p.path
                FROM tbl_photos p
                WHERE (p.photo_id = r.id OR p.id = r.id)
                  AND p.path IS NOT NULL
                  AND TRIM(p.path) != ''
                ORDER BY p.id DESC
                LIMIT 1
              )), '')
            ) as resolved_image_path,
            COALESCE(
              NULLIF(TRIM((
                SELECT p.image_url
                FROM tbl_photos p
                WHERE (p.photo_id = r.id OR p.id = r.id)
                  AND p.image_url IS NOT NULL
                  AND TRIM(p.image_url) != ''
                ORDER BY p.id DESC
                LIMIT 1
              )), ''),
              ''
            ) as resolved_image_url
      FROM tbl_scan_record r
      LEFT JOIN tbl_tree t ON r.tree_id = t.id
      LEFT JOIN tbl_disease d ON r.disease_id = d.id
      LEFT JOIN tbl_severity_level s ON r.severity_level_id = s.id
      ORDER BY COALESCE(
        datetime(replace(replace(substr(r.scan_timestamp, 1, 19), 'T', ' '), 'Z', '')),
        r.scan_timestamp
      ) DESC,
      r.id DESC
    ''');
    return rows
        .map(
          (row) => ScanItem(
            id: row['id'] as int,
            title: row['resolved_disease'] as String? ?? '',
            description: '',
            timestamp: row['scan_timestamp'] as String? ?? '',
            imagePath: row['resolved_image_path'] as String? ?? '',
            imageUrl: row['resolved_image_url'] as String? ?? '',
            checksum: '',
            source: row['source'] as String? ?? '',
            updatedAt: row['analysis_updated_at'] as String? ?? '',
            disease: row['resolved_disease'] as String? ?? '',
            diseaseClass: row['disease_class'] as String? ?? '',
            confidence: (row['confidence_score'] as num?)?.toDouble() ?? 0.0,
            severityValue:
                (row['severity_percentage'] as num?)?.toDouble() ?? 0.0,
            photoId: null, // No photo_id in new schema
            scanDir: '',
            treeId: row['tree_id'] as int?,
            treeName: row['tree_name'] as String? ?? '',
            treeLocation: row['tree_location'] as String? ?? '',
            treeVariety: row['tree_variety'] as String? ?? '',
            diseaseId: row['disease_id'] as int?,
            diseaseName: row['disease_name'] as String? ?? '',
            diseaseDescription: row['disease_description'] as String? ?? '',
            diseaseSymptoms: row['disease_symptoms'] as String? ?? '',
            diseasePrevention: row['disease_prevention'] as String? ?? '',
            severityLevelId: row['severity_level_id'] as int?,
            severityLevelName: row['resolved_severity_name'] as String? ?? '',
            severityLevelDescription:
                row['severity_description'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<void> batchUpsertScans(List<ScanItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      // Build caches for lookups
      final diseaseCache = <String, int>{};
      final severityCache = <String, int>{};
      final treeCache = <String, int>{};

      // Pre-populate caches with existing data
      final existingDiseases = await txn.query(
        'tbl_disease',
        columns: ['id', 'name'],
      );
      for (final row in existingDiseases) {
        diseaseCache[row['name'] as String] = row['id'] as int;
      }

      final existingSeverities = await txn.query(
        'tbl_severity_level',
        columns: ['id', 'name'],
      );
      for (final row in existingSeverities) {
        severityCache[row['name'] as String] = row['id'] as int;
      }

      final existingTrees = await txn.query(
        'tbl_tree',
        columns: ['id', 'name'],
      );
      for (final row in existingTrees) {
        treeCache[row['name'] as String] = row['id'] as int;
      }

      for (final item in items) {
        // Upsert tree
        int? treeId = item.treeId;
        if (treeId == null && item.treeName.isNotEmpty) {
          treeId = treeCache[item.treeName];
          if (treeId == null) {
            treeId = await txn.insert('tbl_tree', {
              'name': item.treeName,
              'location': item.treeLocation,
              'variety': item.treeVariety,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
            treeCache[item.treeName] = treeId;
          }
        }

        // Upsert disease
        final diseaseName = _resolvedDiseaseName(item);
        int? diseaseId = item.diseaseId;
        if (diseaseId == null && diseaseName.isNotEmpty) {
          diseaseId = diseaseCache[diseaseName];
          if (diseaseId == null) {
            diseaseId = await txn.insert('tbl_disease', {
              'name': diseaseName,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
            diseaseCache[diseaseName] = diseaseId;
          }
        }

        // Upsert severity level
        final resolvedSeverityName = _resolvedSeverityName(item);
        int? severityLevelId = item.severityLevelId;
        if (severityLevelId == null) {
          severityLevelId = severityCache[resolvedSeverityName];
          if (severityLevelId == null) {
            severityLevelId = await txn.insert('tbl_severity_level', {
              'name': resolvedSeverityName,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
            severityCache[resolvedSeverityName] = severityLevelId;
          }
        }

        // Insert/update scan record
        await txn.insert('tbl_scan_record', {
          'id': item.id,
          'tree_id': treeId,
          'disease_id': diseaseId,
          'severity_level_id': severityLevelId,
          'scan_timestamp': item.timestamp,
          'disease_class': diseaseName,
          'confidence_score': item.confidence,
          'severity_percentage': item.severityValue,
          'severity_level': resolvedSeverityName,
          'image_path': item.imagePath,
          'source': item.source,
          'analysis_updated_at': item.updatedAt,
          'is_archived': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<ScanSummary> getScanSummary() async {
    final db = await database;
    final rows = await db.rawQuery('''
      WITH normalized AS (
        SELECT
          LOWER(TRIM(COALESCE(NULLIF(r.severity_level, ''), NULLIF(s.name, ''), ''))) AS severity_text,
          LOWER(TRIM(COALESCE(NULLIF(r.disease_class, ''), NULLIF(d.name, ''), ''))) AS disease_text,
          COALESCE(r.severity_percentage, 0) AS severity_pct
        FROM tbl_scan_record r
        LEFT JOIN tbl_severity_level s ON r.severity_level_id = s.id
        LEFT JOIN tbl_disease d ON r.disease_id = d.id
      ),
      buckets AS (
        SELECT
          CASE
            WHEN severity_text LIKE '%healthy%' OR disease_text = 'healthy' THEN 'healthy'
            WHEN severity_text LIKE '%advanced%' OR severity_text LIKE '%severe%' OR severity_text LIKE '%critical%' THEN 'advanced'
            WHEN severity_text LIKE '%early%' OR severity_text LIKE '%moderate%' OR severity_text LIKE '%mid%' THEN 'early'
            WHEN severity_pct > 40.0 THEN 'advanced'
            WHEN severity_pct > 5.0 THEN 'early'
            ELSE 'healthy'
          END AS bucket
        FROM normalized
      )
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN bucket = 'advanced' THEN 1 ELSE 0 END) as advanced_stage,
        SUM(CASE WHEN bucket = 'early' THEN 1 ELSE 0 END) as early_stage,
        SUM(CASE WHEN bucket = 'healthy' THEN 1 ELSE 0 END) as healthy
      FROM buckets
    ''');

    if (rows.isEmpty) {
      return ScanSummary(
        totalScans: 0,
        healthyCount: 0,
        earlyStageCount: 0,
        advancedStageCount: 0,
      );
    }

    final row = rows.first;
    return ScanSummary(
      totalScans: row['total'] as int? ?? 0,
      healthyCount: row['healthy'] as int? ?? 0,
      earlyStageCount: row['early_stage'] as int? ?? 0,
      advancedStageCount: row['advanced_stage'] as int? ?? 0,
    );
  }

  Future<List<double>> getWeeklyTrend() async {
    final db = await database;
    final rows = await db.rawQuery('''
      WITH normalized AS (
        SELECT
          datetime(replace(replace(substr(scan_timestamp, 1, 19), 'T', ' '), 'Z', '')) AS normalized_ts
        FROM tbl_scan_record
        WHERE scan_timestamp IS NOT NULL AND TRIM(scan_timestamp) != ''
      )
      SELECT
        strftime('%Y-%W', normalized_ts) as week,
        COUNT(*) as count
      FROM normalized
      WHERE normalized_ts IS NOT NULL
      GROUP BY week
      ORDER BY week DESC
      LIMIT 11
    ''');
    // Return the counts in chronological order (oldest first)
    final reversed = rows.reversed
        .map((row) => (row['count'] as int).toDouble())
        .toList();
    return reversed;
  }

  Future<List<Map<String, dynamic>>> getDiseaseDistribution() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(NULLIF(TRIM(d.name), ''), NULLIF(TRIM(r.disease_class), ''), 'Unknown') AS disease,
        COUNT(*) AS count
      FROM tbl_scan_record r
      LEFT JOIN tbl_disease d ON r.disease_id = d.id
      GROUP BY COALESCE(NULLIF(TRIM(d.name), ''), NULLIF(TRIM(r.disease_class), ''), 'Unknown')
      ORDER BY count DESC
    ''');
    return rows;
  }

  Future<String> getPrimaryDiseaseName() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(NULLIF(TRIM(d.name), ''), NULLIF(TRIM(r.disease_class), ''), 'Unknown') AS disease,
        COUNT(*) AS count
      FROM tbl_scan_record r
      LEFT JOIN tbl_disease d ON r.disease_id = d.id
      WHERE LOWER(COALESCE(NULLIF(d.name, ''), NULLIF(r.disease_class, ''), '')) NOT IN ('healthy', 'unknown', '')
      GROUP BY COALESCE(NULLIF(TRIM(d.name), ''), NULLIF(TRIM(r.disease_class), ''), 'Unknown')
      ORDER BY count DESC
      LIMIT 1
    ''');
    if (rows.isEmpty) return 'No Active Disease';
    return rows.first['disease']?.toString() ?? 'No Active Disease';
  }

  Future<ScanItem?> getScanById(int id) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT r.*, t.name as tree_name, t.location as tree_location, t.variety as tree_variety,
             d.name as disease_name, d.description as disease_description, d.symptoms as disease_symptoms, d.prevention as disease_prevention,
            s.name as severity_name, s.description as severity_description,
            COALESCE(NULLIF(TRIM(d.name), ''), NULLIF(TRIM(r.disease_class), ''), '') as resolved_disease,
        COALESCE(NULLIF(TRIM(r.severity_level), ''), NULLIF(TRIM(s.name), ''), '') as resolved_severity_name,
        COALESCE(
          NULLIF(TRIM(r.image_path), ''),
          NULLIF(TRIM(r.thumbnail_path), ''),
          NULLIF(TRIM((
            SELECT p.path
            FROM tbl_photos p
            WHERE (p.photo_id = r.id OR p.id = r.id)
              AND p.path IS NOT NULL
              AND TRIM(p.path) != ''
            ORDER BY p.id DESC
            LIMIT 1
          )), '')
        ) as resolved_image_path,
        COALESCE(
          NULLIF(TRIM((
            SELECT p.image_url
            FROM tbl_photos p
            WHERE (p.photo_id = r.id OR p.id = r.id)
              AND p.image_url IS NOT NULL
              AND TRIM(p.image_url) != ''
            ORDER BY p.id DESC
            LIMIT 1
          )), ''),
          ''
        ) as resolved_image_url
      FROM tbl_scan_record r
      LEFT JOIN tbl_tree t ON r.tree_id = t.id
      LEFT JOIN tbl_disease d ON r.disease_id = d.id
      LEFT JOIN tbl_severity_level s ON r.severity_level_id = s.id
      WHERE r.id = ?
    ''',
      [id],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ScanItem(
      id: row['id'] as int,
      title: row['resolved_disease'] as String? ?? '',
      description: '',
      timestamp: row['scan_timestamp'] as String? ?? '',
      imagePath: row['resolved_image_path'] as String? ?? '',
      imageUrl: row['resolved_image_url'] as String? ?? '',
      checksum: '',
      source: row['source'] as String? ?? '',
      updatedAt: row['analysis_updated_at'] as String? ?? '',
      disease: row['resolved_disease'] as String? ?? '',
      diseaseClass: row['disease_class'] as String? ?? '',
      confidence: (row['confidence_score'] as num?)?.toDouble() ?? 0.0,
      severityValue: (row['severity_percentage'] as num?)?.toDouble() ?? 0.0,
      photoId: null,
      scanDir: '',
      treeId: row['tree_id'] as int?,
      treeName: row['tree_name'] as String? ?? '',
      treeLocation: row['tree_location'] as String? ?? '',
      treeVariety: row['tree_variety'] as String? ?? '',
      diseaseId: row['disease_id'] as int?,
      diseaseName: row['disease_name'] as String? ?? '',
      diseaseDescription: row['disease_description'] as String? ?? '',
      diseaseSymptoms: row['disease_symptoms'] as String? ?? '',
      diseasePrevention: row['disease_prevention'] as String? ?? '',
      severityLevelId: row['severity_level_id'] as int?,
      severityLevelName: row['resolved_severity_name'] as String? ?? '',
      severityLevelDescription: row['severity_description'] as String? ?? '',
    );
  }

  Future<void> deleteScan(int id) async {
    final db = await database;
    await db.delete('tbl_scan_record', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllScans() async {
    final db = await database;
    await db.delete('tbl_scan_record');
  }

  Future<void> updateScanImagePath(int scanId, String localPath) async {
    final db = await database;
    await db.update(
      'tbl_scan_record',
      {'image_path': localPath},
      where: 'id = ?',
      whereArgs: [scanId],
    );
  }

  Future<List<Map<String, dynamic>>> getImportableScanImages() async {
    final db = await database;
    final rows = await db.rawQuery('''
      WITH resolved AS (
        SELECT
          r.id,
          r.scan_timestamp,
          COALESCE(NULLIF(TRIM(d.name), ''), NULLIF(TRIM(r.disease_class), ''), 'Unknown') as disease_class,
          COALESCE(
            NULLIF(TRIM(r.image_path), ''),
            NULLIF(TRIM(r.thumbnail_path), ''),
            NULLIF(TRIM((
              SELECT p.path
              FROM tbl_photos p
              WHERE (p.photo_id = r.id OR p.id = r.id)
                AND p.path IS NOT NULL
                AND TRIM(p.path) != ''
              ORDER BY p.id DESC
              LIMIT 1
            )), '')
          ) as image_path,
          r.thumbnail_path,
          COALESCE(
            NULLIF(TRIM((
              SELECT p.image_url
              FROM tbl_photos p
              WHERE (p.photo_id = r.id OR p.id = r.id)
                AND p.image_url IS NOT NULL
                AND TRIM(p.image_url) != ''
              ORDER BY p.id DESC
              LIMIT 1
            )), ''),
            ''
          ) as image_url,
          r.confidence_score as confidence,
          r.severity_percentage as severity_value,
          COALESCE(NULLIF(TRIM(r.severity_level), ''), NULLIF(TRIM(s.name), ''), '') as severity_label,
          r.analysis_updated_at as updated_at,
          r.source
        FROM tbl_scan_record r
        LEFT JOIN tbl_disease d ON r.disease_id = d.id
        LEFT JOIN tbl_severity_level s ON r.severity_level_id = s.id
      )
      SELECT *
      FROM resolved
      WHERE
        (image_path IS NOT NULL AND TRIM(image_path) != '') OR
        (image_url IS NOT NULL AND TRIM(image_url) != '')
      ORDER BY COALESCE(
        datetime(replace(replace(substr(scan_timestamp, 1, 19), 'T', ' '), 'Z', '')),
        scan_timestamp
      ) DESC,
      id DESC
    ''');
    return rows;
  }

  Future<List<Map<String, dynamic>>> getScanImageCandidates() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        id,
        COALESCE(
          NULLIF(TRIM(image_path), ''),
          NULLIF(TRIM(thumbnail_path), '')
        ) AS image_path
      FROM tbl_scan_record
      WHERE COALESCE(
        NULLIF(TRIM(image_path), ''),
        NULLIF(TRIM(thumbnail_path), '')
      ) IS NOT NULL
      ORDER BY id DESC
    ''');
  }

  // Photos
  Future<int> insertPhoto({
    required String name,
    String? data,
    String? path,
    required String timestamp,
    String? title,
    String? description,
    String? imageUrl,
    String? checksum,
    String? source,
    String? updatedAt,
    String? disease,
    double? confidence,
    double? severityValue,
    int? photoId,
    String? scanDir,
  }) async {
    final db = await database;

    return await db.insert('tbl_photos', {
      'name': name,
      'data': data ?? '', // Always provide a value for NOT NULL column
      'timestamp': timestamp,
      if (path != null) 'path': path,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (checksum != null) 'checksum': checksum,
      if (source != null) 'source': source,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (disease != null) 'disease': disease,
      if (confidence != null) 'confidence': confidence,
      if (severityValue != null) 'severity_value': severityValue,
      if (photoId != null) 'photo_id': photoId,
      if (scanDir != null) 'scan_dir': scanDir,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllPhotos() async {
    final db = await database;
    return await db.query('tbl_photos', orderBy: "id DESC");
  }

  Future<List<Map<String, dynamic>>> getAllPhotoMetadata() async {
    final db = await database;
    return await db.query(
      'tbl_photos',
      columns: [
        'id',
        'name',
        'timestamp',
        'path',
        'title',
        'description',
        'image_url',
        'checksum',
        'source',
        'updated_at',
        'disease',
        'confidence',
        'severity_value',
        'photo_id',
        'scan_dir',
      ],
      orderBy: "id DESC",
    );
  }

  Future<Map<String, dynamic>?> getPhotoById(int id) async {
    final db = await database;
    final results = await db.query(
      'tbl_photos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getPhotosByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final results = await db.query(
      'tbl_photos',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return results;
  }

  Future<int> deletePhoto(int id) async {
    final db = await database;
    return db.delete('tbl_photos', where: "id = ?", whereArgs: [id]);
  }

  Future<int?> getPhotoIdByNameTimestamp(String name, String timestamp) async {
    final db = await database;
    final results = await db.query(
      'tbl_photos',
      columns: ['id'],
      where: 'name = ? AND timestamp = ?',
      whereArgs: [name, timestamp],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first['id'] as int;
    }
    return null;
  }

  // My Trees
  Future<int> insertMyTree({
    required String title,
    String? location,
    String? images,
    String? coverImage,
  }) async {
    final db = await database;
    return await db.insert('tbl_my_trees', {
      'title': title,
      'location': location ?? '',
      'images': images ?? '',
      'cover_image': coverImage ?? 'images/leaf.png',
    });
  }

  Future<List<Map<String, dynamic>>> getAllMyTrees() async {
    final db = await database;
    return await db.query('tbl_my_trees', orderBy: "id DESC");
  }

  Future<int> updateMyTree(
    int id, {
    String? title,
    String? location,
    String? images,
    String? coverImage,
  }) async {
    final db = await database;
    final Map<String, dynamic> updates = {};
    if (title != null) updates['title'] = title;
    if (location != null) updates['location'] = location;
    if (images != null) updates['images'] = images;
    if (coverImage != null) updates['cover_image'] = coverImage;

    return await db.update(
      'tbl_my_trees',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateMyTreeTitle(String oldTitle, String newTitle) async {
    final db = await database;
    return await db.update(
      'tbl_my_trees',
      {'title': newTitle},
      where: 'title = ?',
      whereArgs: [oldTitle],
    );
  }

  Future<int> deleteMyTree(int id) async {
    final db = await database;
    return await db.delete('tbl_my_trees', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteMyTreeByTitle(String title) async {
    final db = await database;
    return await db.delete(
      'tbl_my_trees',
      where: 'title = ?',
      whereArgs: [title],
    );
  }

  // Dataset folders
  Future<int> insertDatasetFolder({
    required String name,
    required List<String> imageIds,
    required String dateCreated,
  }) async {
    final db = await database;
    return await db.insert('tbl_dataset_folders', {
      'name': name,
      'images': imageIds.join(','),
      'date_created': dateCreated,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DatasetFolder>> getAllDatasetFolders() async {
    final db = await database;
    final maps = await db.query('tbl_dataset_folders', orderBy: 'id DESC');
    return maps.map((m) => DatasetFolder.fromMap(m)).toList();
  }

  Future<int> updateDatasetFolderName(String oldName, String newName) async {
    final db = await database;
    return await db.update(
      'tbl_dataset_folders',
      {'name': newName},
      where: 'name = ?',
      whereArgs: [oldName],
    );
  }

  Future<int> deleteDatasetFolder(String name) async {
    final db = await database;
    return await db.delete(
      'tbl_dataset_folders',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  Future<void> removeImageFromDatasetFolder(
    String folderName,
    String imageIdToRemove,
  ) async {
    final db = await database;

    final rows = await db.query(
      'tbl_dataset_folders',
      where: 'name = ?',
      whereArgs: [folderName],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final folder = DatasetFolder.fromMap(rows.first);
    final updatedImages = folder.images
        .where((id) => id.trim().isNotEmpty && id != imageIdToRemove)
        .toList();

    if (updatedImages.isEmpty) {
      await deleteDatasetFolder(folderName);
      return;
    }

    await db.update(
      'tbl_dataset_folders',
      {'images': updatedImages.join(',')},
      where: 'name = ?',
      whereArgs: [folderName],
    );
  }
}
