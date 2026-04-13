import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../model/scan_item.dart';
import '../model/scan_summary_model.dart';

class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

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

    return await openDatabase(
      path,
      version: 4,
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

        // Create indexes
        await db.execute('CREATE INDEX IF NOT EXISTS idx_tree_name ON tbl_tree(name)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_record_disease ON tbl_scan_record(disease_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_record_severity ON tbl_scan_record(severity_level_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_record_tree ON tbl_scan_record(tree_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_scan_archived ON tbl_scan_record(is_archived)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_scan_archived_timestamp ON tbl_scan_record(is_archived, scan_timestamp DESC)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_scan_record_timestamp ON tbl_scan_record(scan_timestamp)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_scan_tree_archived ON tbl_scan_record(tree_id, is_archived)');
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
      },
    );
  }

  Future<void> replaceDatabaseFromFile(String sourcePath, {bool keepBackup = true}) async {
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
        final requiredTables = ['tbl_tree', 'tbl_disease', 'tbl_severity_level', 'tbl_scan_record'];
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
        final scanColumns = await db.rawQuery("PRAGMA table_info(tbl_scan_record)");
        final columnNames = scanColumns.map((row) => row['name'] as String).toSet();
        final requiredScanColumns = {'id', 'scan_timestamp', 'disease_class', 'image_path'};
        if (!requiredScanColumns.every(columnNames.contains)) {
          throw Exception('Imported DB tbl_scan_record missing essential columns: ${requiredScanColumns.where((c) => !columnNames.contains(c)).join(', ')}');
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

  Future<void> upsertScan(ScanItem item) async {
    final db = await database;

    // Upsert tree if data provided
    int? treeId = item.treeId;
    if (treeId != null && item.treeName.isNotEmpty) {
      await db.insert(
        'tbl_tree',
        {
          'id': treeId,
          'name': item.treeName,
          'location': item.treeLocation,
          'variety': item.treeVariety,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Upsert disease if data provided
    int? diseaseId = item.diseaseId;
    if (diseaseId != null && item.diseaseName.isNotEmpty) {
      await db.insert(
        'tbl_disease',
        {
          'id': diseaseId,
          'name': item.diseaseName,
          'description': item.diseaseDescription,
          'symptoms': item.diseaseSymptoms,
          'prevention': item.diseasePrevention,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Upsert severity level if data provided
    int? severityLevelId = item.severityLevelId;
    if (severityLevelId != null && item.severityLevelName.isNotEmpty) {
      await db.insert(
        'tbl_severity_level',
        {
          'id': severityLevelId,
          'name': item.severityLevelName,
          'description': item.severityLevelDescription,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Fallback to old logic if IDs not provided
    if (treeId == null && item.treeName.isNotEmpty) {
      final treeRows = await db.query('tbl_tree', where: 'name = ?', whereArgs: [item.treeName]);
      if (treeRows.isEmpty) {
        treeId = await db.insert('tbl_tree', {'name': item.treeName, 'location': item.treeLocation, 'variety': item.treeVariety});
      } else {
        treeId = treeRows.first['id'] as int;
      }
    }

    if (diseaseId == null && item.disease.isNotEmpty) {
      final diseaseRows = await db.query('tbl_disease', where: 'name = ?', whereArgs: [item.disease]);
      if (diseaseRows.isEmpty) {
        diseaseId = await db.insert('tbl_disease', {'name': item.disease});
      } else {
        diseaseId = diseaseRows.first['id'] as int;
      }
    }

    if (severityLevelId == null) {
      String severityLevelName;
      if (item.severityValue > 40.0) {
        severityLevelName = 'Severe';
      } else if (item.severityValue > 5.0) {
        severityLevelName = 'Moderate';
      } else {
        severityLevelName = 'Healthy';
      }

      final severityRows = await db.query('tbl_severity_level', where: 'name = ?', whereArgs: [severityLevelName]);
      if (severityRows.isEmpty) {
        severityLevelId = await db.insert('tbl_severity_level', {'name': severityLevelName});
      } else {
        severityLevelId = severityRows.first['id'] as int;
      }
    }

    await db.insert(
      'tbl_scan_record',
      {
        'id': item.id,
        'tree_id': treeId,
        'disease_id': diseaseId,
        'severity_level_id': severityLevelId,
        'scan_timestamp': item.timestamp,
        'disease_class': item.disease,
        'confidence_score': item.confidence,
        'severity_percentage': item.severityValue,
        'image_path': item.imagePath,
        'source': item.source,
        'analysis_updated_at': item.updatedAt,
        'is_archived': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScanItem>> getAllScans() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT r.*, t.name as tree_name, t.location as tree_location, t.variety as tree_variety,
             d.name as disease_name, d.description as disease_description, d.symptoms as disease_symptoms, d.prevention as disease_prevention,
             s.name as severity_name, s.description as severity_description
      FROM tbl_scan_record r
      LEFT JOIN tbl_tree t ON r.tree_id = t.id
      LEFT JOIN tbl_disease d ON r.disease_id = d.id
      LEFT JOIN tbl_severity_level s ON r.severity_level_id = s.id
      ORDER BY r.scan_timestamp DESC
    ''');
    return rows.map((row) => ScanItem(
      id: row['id'] as int,
      title: row['disease_class'] as String? ?? '',
      description: '',
      timestamp: row['scan_timestamp'] as String? ?? '',
      imagePath: row['image_path'] as String? ?? '',
      imageUrl: row['image_path'] as String? ?? '', // Assuming image_path is the local path
      checksum: '',
      source: row['source'] as String? ?? '',
      updatedAt: row['analysis_updated_at'] as String? ?? '',
      disease: row['disease_class'] as String? ?? '',
      confidence: (row['confidence_score'] as num?)?.toDouble() ?? 0.0,
      severityValue: (row['severity_percentage'] as num?)?.toDouble() ?? 0.0,
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
      severityLevelName: row['severity_name'] as String? ?? '',
      severityLevelDescription: row['severity_description'] as String? ?? '',
    )).toList();
  }

  Future<void> batchUpsertScans(List<ScanItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      // Build caches for lookups
      final diseaseCache = <String, int>{};
      final severityCache = <String, int>{};
      final treeCache = <String, int>{};

      // Pre-populate caches with existing data
      final existingDiseases = await txn.query('tbl_disease', columns: ['id', 'name']);
      for (final row in existingDiseases) {
        diseaseCache[row['name'] as String] = row['id'] as int;
      }

      final existingSeverities = await txn.query('tbl_severity_level', columns: ['id', 'name']);
      for (final row in existingSeverities) {
        severityCache[row['name'] as String] = row['id'] as int;
      }

      final existingTrees = await txn.query('tbl_tree', columns: ['id', 'name']);
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
        int? diseaseId = item.diseaseId;
        if (diseaseId == null && item.disease.isNotEmpty) {
          diseaseId = diseaseCache[item.disease];
          if (diseaseId == null) {
            diseaseId = await txn.insert('tbl_disease', {'name': item.disease}, conflictAlgorithm: ConflictAlgorithm.replace);
            diseaseCache[item.disease] = diseaseId;
          }
        }

        // Upsert severity level
        int? severityLevelId = item.severityLevelId;
        if (severityLevelId == null) {
          String severityLevelName;
          if (item.severityValue > 40.0) {
            severityLevelName = 'Severe';
          } else if (item.severityValue > 5.0) {
            severityLevelName = 'Moderate';
          } else {
            severityLevelName = 'Healthy';
          }

          severityLevelId = severityCache[severityLevelName];
          if (severityLevelId == null) {
            severityLevelId = await txn.insert('tbl_severity_level', {'name': severityLevelName}, conflictAlgorithm: ConflictAlgorithm.replace);
            severityCache[severityLevelName] = severityLevelId;
          }
        }

        // Insert/update scan record
        await txn.insert(
          'tbl_scan_record',
          {
            'id': item.id,
            'tree_id': treeId,
            'disease_id': diseaseId,
            'severity_level_id': severityLevelId,
            'scan_timestamp': item.timestamp,
            'disease_class': item.disease,
            'confidence_score': item.confidence,
            'severity_percentage': item.severityValue,
            'image_path': item.imagePath,
            'source': item.source,
            'analysis_updated_at': item.updatedAt,
            'is_archived': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<ScanSummary> getScanSummary() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN severity_percentage > 40.0 THEN 1 ELSE 0 END) as severe,
        SUM(CASE WHEN severity_percentage > 5.0 AND severity_percentage <= 40.0 THEN 1 ELSE 0 END) as moderate,
        SUM(CASE WHEN severity_percentage <= 5.0 THEN 1 ELSE 0 END) as healthy
      FROM tbl_scan_record
    ''');

    if (rows.isEmpty) {
      return ScanSummary(totalScans: 0, healthyCount: 0, moderateCount: 0, severeCount: 0);
    }

    final row = rows.first;
    return ScanSummary(
      totalScans: row['total'] as int? ?? 0,
      healthyCount: row['healthy'] as int? ?? 0,
      moderateCount: row['moderate'] as int? ?? 0,
      severeCount: row['severe'] as int? ?? 0,
    );
  }

  Future<List<Map<String, dynamic>>> getDiseaseDistribution() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(NULLIF(TRIM(disease_class), ''), 'Unknown') AS disease,
        COUNT(*) AS count
      FROM tbl_scan_record
      GROUP BY disease_class
      ORDER BY count DESC
    ''');
    return rows;
  }

  Future<ScanItem?> getScanById(int id) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT r.*, t.name as tree_name, t.location as tree_location, t.variety as tree_variety,
             d.name as disease_name, d.description as disease_description, d.symptoms as disease_symptoms, d.prevention as disease_prevention,
             s.name as severity_name, s.description as severity_description
      FROM tbl_scan_record r
      LEFT JOIN tbl_tree t ON r.tree_id = t.id
      LEFT JOIN tbl_disease d ON r.disease_id = d.id
      LEFT JOIN tbl_severity_level s ON r.severity_level_id = s.id
      WHERE r.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ScanItem(
      id: row['id'] as int,
      title: row['disease_class'] as String? ?? '',
      description: '',
      timestamp: row['scan_timestamp'] as String? ?? '',
      imagePath: row['image_path'] as String? ?? '',
      imageUrl: row['image_path'] as String? ?? '',
      checksum: '',
      source: row['source'] as String? ?? '',
      updatedAt: row['analysis_updated_at'] as String? ?? '',
      disease: row['disease_class'] as String? ?? '',
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
      severityLevelName: row['severity_name'] as String? ?? '',
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
      SELECT id, title, description, scan_timestamp, image_path, image_url, checksum, source, updated_at, disease_class, confidence, severity_value, photo_id, scan_dir
      FROM tbl_scan_record
      WHERE image_path IS NOT NULL AND image_path != ''
      ORDER BY scan_timestamp DESC
    ''');
    return rows;
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
    return await db.query('tbl_photos',
      columns: ['id', 'name', 'timestamp', 'path', 'title', 'description', 'image_url', 'checksum', 'source', 'updated_at', 'disease', 'confidence', 'severity_value', 'photo_id', 'scan_dir'],
      orderBy: "id DESC");
  }

  Future<Map<String, dynamic>?> getPhotoById(int id) async {
    final db = await database;
    final results = await db.query('tbl_photos', where: 'id = ?', whereArgs: [id], limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getPhotosByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final results = await db.query('tbl_photos', where: 'id IN ($placeholders)', whereArgs: ids);
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

  Future<int> updateMyTree(int id, {
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
    return await db.delete('tbl_my_trees', where: 'title = ?', whereArgs: [title]);
  }
}
