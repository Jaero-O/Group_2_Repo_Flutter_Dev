import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../model/scan_item.dart';
import '../model/scan_summary_model.dart';
import '../model/dataset_folder_model.dart';
import '../model/action_item.dart';
import '../model/orchard_snapshot.dart';
import '../model/scan_classification.dart';
import '../model/weather_data.dart';

class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();
  static const String _legacyDataMigrationFlag =
      'legacy_local_db_data_migrated_v1';

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
      version: 8,
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
            location TEXT NOT NULL DEFAULT '',
            images TEXT NOT NULL,
            date_created TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE tbl_action_library(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            disease_keyword TEXT NOT NULL,
            severity_trigger TEXT NOT NULL DEFAULT 'all',
            trend_trigger TEXT NOT NULL DEFAULT 'any',
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            icon_code INTEGER NOT NULL,
            color_hex TEXT NOT NULL DEFAULT '#2E7D32',
            priority INTEGER NOT NULL DEFAULT 100,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE tbl_weather_cache(
            id INTEGER PRIMARY KEY,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            fetched_at TEXT NOT NULL,
            temp_c REAL NOT NULL,
            humidity_pct REAL NOT NULL,
            rainfall_mm REAL NOT NULL,
            wind_speed REAL NOT NULL,
            condition TEXT NOT NULL,
            raw_json TEXT NOT NULL
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
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_action_lookup ON tbl_action_library(disease_keyword, severity_trigger, trend_trigger, is_active, priority)',
        );

        await _seedKnownDiseases(db);
        await _seedActionLibrary(db);
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
              location TEXT NOT NULL DEFAULT '',
              images TEXT NOT NULL,
              date_created TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 6) {
          final datasetFolderCols = await db.rawQuery(
            'PRAGMA table_info(tbl_dataset_folders)',
          );
          final hasLocationColumn = datasetFolderCols.any(
            (row) => row['name'] == 'location',
          );
          if (!hasLocationColumn) {
            await db.execute(
              "ALTER TABLE tbl_dataset_folders ADD COLUMN location TEXT NOT NULL DEFAULT ''",
            );
          }
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tbl_action_library(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              disease_keyword TEXT NOT NULL,
              severity_trigger TEXT NOT NULL DEFAULT 'all',
              trend_trigger TEXT NOT NULL DEFAULT 'any',
              title TEXT NOT NULL,
              description TEXT NOT NULL,
              icon_code INTEGER NOT NULL,
              color_hex TEXT NOT NULL DEFAULT '#2E7D32',
              priority INTEGER NOT NULL DEFAULT 100,
              is_active INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              updated_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tbl_weather_cache(
              id INTEGER PRIMARY KEY,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              fetched_at TEXT NOT NULL,
              temp_c REAL NOT NULL,
              humidity_pct REAL NOT NULL,
              rainfall_mm REAL NOT NULL,
              wind_speed REAL NOT NULL,
              condition TEXT NOT NULL,
              raw_json TEXT NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_action_lookup ON tbl_action_library(disease_keyword, severity_trigger, trend_trigger, is_active, priority)',
          );
          await _seedActionLibrary(db);
        }
        if (oldVersion < 8) {
          await _seedKnownDiseases(db);
          await _repairScanDiseaseForeignKeys(db);
          await _repairLegacyDatasetFolderImageIds(db);
          await _refreshDefaultActionLibraryContent(db);
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
              'location': row['location']?.toString() ?? '',
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
              'cover_image':
                  row['cover_image']?.toString() ?? 'images/leaf.png',
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

  String? _nonEmptyOrNull(String? value) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _canonicalDiseaseName(String raw) {
    final normalized = raw
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
    if (normalized.isEmpty || isGenericDetectionLabel(normalized)) return '';
    if (normalized == 'unknown disease' || normalized == 'unknown') return '';
    if (normalized.contains('anthracnose')) return 'Anthracnose';
    if (normalized.contains('powdery') && normalized.contains('mildew')) {
      return 'Powdery Mildew';
    }
    if (normalized.contains('stem') && normalized.contains('rot')) {
      return 'Stem-End Rot';
    }
    if (normalized.contains('die') && normalized.contains('back')) {
      return 'Die Back';
    }
    if (normalized.contains('canker')) return 'Canker';
    if (normalized == 'healthy') return 'Healthy';
    return formatDiseaseClassLabel(normalized);
  }

  Future<int?> _ensureDiseaseByName(
    DatabaseExecutor executor,
    String diseaseName, {
    String? description,
    String? symptoms,
    String? prevention,
    Map<String, int>? cache,
  }) async {
    final canonicalName = _canonicalDiseaseName(diseaseName);
    if (canonicalName.isEmpty) return null;

    final cacheKey = canonicalName.toLowerCase();
    final cached = cache?[cacheKey];
    if (cached != null) {
      await executor.rawUpdate(
        '''
        UPDATE tbl_disease
        SET
          name = ?,
          description = COALESCE(?, NULLIF(TRIM(description), ''), description),
          symptoms = COALESCE(?, NULLIF(TRIM(symptoms), ''), symptoms),
          prevention = COALESCE(?, NULLIF(TRIM(prevention), ''), prevention)
        WHERE id = ?
        ''',
        [
          canonicalName,
          _nonEmptyOrNull(description),
          _nonEmptyOrNull(symptoms),
          _nonEmptyOrNull(prevention),
          cached,
        ],
      );
      return cached;
    }

    final existing = await executor.query(
      'tbl_disease',
      columns: ['id'],
      where: 'LOWER(TRIM(name)) = ?',
      whereArgs: [cacheKey],
      limit: 1,
    );

    int? diseaseId;
    if (existing.isNotEmpty) {
      diseaseId = existing.first['id'] as int;
    } else {
      diseaseId = await executor.insert('tbl_disease', {
        'name': canonicalName,
        'description': _nonEmptyOrNull(description),
        'symptoms': _nonEmptyOrNull(symptoms),
        'prevention': _nonEmptyOrNull(prevention),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      if (diseaseId <= 0) {
        final rows = await executor.query(
          'tbl_disease',
          columns: ['id'],
          where: 'LOWER(TRIM(name)) = ?',
          whereArgs: [cacheKey],
          limit: 1,
        );
        diseaseId = rows.isNotEmpty ? rows.first['id'] as int : null;
      }
    }

    if (diseaseId == null) return null;
    cache?[cacheKey] = diseaseId;

    await executor.rawUpdate(
      '''
      UPDATE tbl_disease
      SET
        name = ?,
        description = COALESCE(?, NULLIF(TRIM(description), ''), description),
        symptoms = COALESCE(?, NULLIF(TRIM(symptoms), ''), symptoms),
        prevention = COALESCE(?, NULLIF(TRIM(prevention), ''), prevention)
      WHERE id = ?
      ''',
      [
        canonicalName,
        _nonEmptyOrNull(description),
        _nonEmptyOrNull(symptoms),
        _nonEmptyOrNull(prevention),
        diseaseId,
      ],
    );

    return diseaseId;
  }

  Future<void> _seedKnownDiseases(Database db) async {
    const diseaseSeeds = <Map<String, String>>[
      {
        'name': 'Anthracnose',
        'description':
            'Anthracnose is caused by Colletotrichum gloeosporioides and is favored by prolonged leaf wetness, frequent rain, and dense canopy humidity.',
        'symptoms':
            'Dark to black lesions on leaves, flowers, and fruit; blossom blight and fruit spotting can expand rapidly during wet weather.',
        'prevention':
            'Prune to improve airflow, remove infected debris, and apply protectant fungicides such as copper or mancozeb at labeled intervals during high-risk periods.',
      },
      {
        'name': 'Powdery Mildew',
        'description':
            'Powdery mildew (Oidium mangiferae) infects young shoots, panicles, and fruit, especially when nights are humid and mornings are dry.',
        'symptoms':
            'White powder-like fungal growth on flower panicles and tender leaves, followed by flower drop, poor fruit set, and surface russeting.',
        'prevention':
            'Apply sulfur or other labeled mildew fungicides early, manage canopy humidity, and avoid prolonged shade in dense tree sections.',
      },
      {
        'name': 'Stem-End Rot',
        'description':
            'Stem-end rot is commonly associated with Lasiodiplodia theobromae and often appears after harvest when latent infections become active.',
        'symptoms':
            'Soft dark decay starting from the stem end of fruit, progressing inward during storage and transport.',
        'prevention':
            'Reduce harvest injury, maintain orchard sanitation, and use pre-harvest/post-harvest treatments permitted in local production guidelines.',
      },
      {
        'name': 'Die Back',
        'description':
            'Die back is linked to fungal infection and stress-related decline, often advancing from twig tips toward larger branches.',
        'symptoms':
            'Progressive drying of shoot tips, bark discoloration, branch death, and occasional gum exudation.',
        'prevention':
            'Prune below diseased tissue, disinfect tools between cuts, and protect major cuts with labeled fungicide or wound dressing.',
      },
      {
        'name': 'Canker',
        'description':
            'Mango canker can be associated with bacterial or fungal pathogens that enter through wounds and stressed tissues.',
        'symptoms':
            'Sunken or cracked bark lesions, twig cankers, branch decline, and possible gumming on affected stems.',
        'prevention':
            'Remove infected parts, sanitize equipment, avoid wounding during wet periods, and apply registered copper-based protection when risk is high.',
      },
    ];

    for (final seed in diseaseSeeds) {
      final name = seed['name']!;
      await _ensureDiseaseByName(
        db,
        name,
        description: seed['description'],
        symptoms: seed['symptoms'],
        prevention: seed['prevention'],
      );
    }
  }

  Future<void> _repairScanDiseaseForeignKeys(Database db) async {
    final rows = await db.query(
      'tbl_scan_record',
      columns: ['id', 'disease_id', 'disease_class'],
    );
    if (rows.isEmpty) return;

    final cache = <String, int>{};
    await db.transaction((txn) async {
      for (final row in rows) {
        final scanId = row['id'] as int;
        final currentDiseaseId = row['disease_id'] as int?;
        final diseaseClass = (row['disease_class']?.toString() ?? '').trim();
        if (diseaseClass.isEmpty) continue;

        final repairedId = await _ensureDiseaseByName(
          txn,
          diseaseClass,
          cache: cache,
        );
        if (repairedId == null || repairedId == currentDiseaseId) continue;

        await txn.update(
          'tbl_scan_record',
          {'disease_id': repairedId},
          where: 'id = ?',
          whereArgs: [scanId],
        );
      }
    });
  }

  Future<void> _repairLegacyDatasetFolderImageIds(Database db) async {
    final rows = await db.query(
      'tbl_dataset_folders',
      columns: ['id', 'images'],
    );
    if (rows.isEmpty) return;

    await db.transaction((txn) async {
      for (final row in rows) {
        final folderId = row['id'] as int;
        final raw = (row['images']?.toString() ?? '').trim();
        if (raw.isEmpty) continue;

        bool changed = false;
        final repaired = <String>[];
        final seen = <String>{};

        for (final token in raw.split(',')) {
          final trimmed = token.trim();
          if (trimmed.isEmpty) continue;
          final parsed = int.tryParse(trimmed);
          if (parsed == null) {
            if (seen.add(trimmed)) repaired.add(trimmed);
            continue;
          }

          final scanExists = await txn.query(
            'tbl_scan_record',
            columns: ['id'],
            where: 'id = ?',
            whereArgs: [parsed],
            limit: 1,
          );
          if (scanExists.isNotEmpty) {
            final idStr = parsed.toString();
            if (seen.add(idStr)) repaired.add(idStr);
            continue;
          }

          final mapped = await txn.query(
            'tbl_photos',
            columns: ['photo_id'],
            where: 'id = ? AND photo_id IS NOT NULL',
            whereArgs: [parsed],
            limit: 1,
          );
          if (mapped.isEmpty) {
            if (seen.add(trimmed)) repaired.add(trimmed);
            continue;
          }

          final mappedScanId = mapped.first['photo_id'] as int?;
          if (mappedScanId == null) {
            if (seen.add(trimmed)) repaired.add(trimmed);
            continue;
          }

          final mappedStr = mappedScanId.toString();
          if (mappedStr != trimmed) changed = true;
          if (seen.add(mappedStr)) repaired.add(mappedStr);
        }

        if (!changed) continue;

        await txn.update(
          'tbl_dataset_folders',
          {'images': repaired.join(',')},
          where: 'id = ?',
          whereArgs: [folderId],
        );
      }
    });
  }

  Future<void> _refreshDefaultActionLibraryContent(Database db) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    const updates = <Map<String, String>>[
      {
        'disease_keyword': 'default',
        'title': 'Apply Fungicide',
        'description':
            'During wet conditions, apply a labeled protectant spray such as copper hydroxide or mancozeb and follow local pre-harvest intervals.',
      },
      {
        'disease_keyword': 'default',
        'title': 'Improve Drainage',
        'description':
            'Keep root zones free from standing water and clear drainage canals before heavy rain periods.',
      },
      {
        'disease_keyword': 'default',
        'title': 'Remove Infected Leaves',
        'description':
            'Collect and destroy infected leaves, twigs, and fruit debris to reduce inoculum between flushes.',
      },
      {
        'disease_keyword': 'anthracnose',
        'title': 'Targeted Fungicide Spray',
        'description':
            'Start preventive copper or mancozeb sprays at flowering and repeat at label intervals when rainfall and humidity remain high.',
      },
      {
        'disease_keyword': 'anthracnose',
        'title': 'Prune Infected Growth',
        'description':
            'Prune visibly infected twigs 10-15 cm below lesions and destroy cuttings away from productive blocks.',
      },
      {
        'disease_keyword': 'anthracnose',
        'title': 'Improve Air Flow',
        'description':
            'Open dense canopy sections to shorten leaf wetness duration and reduce anthracnose infection pressure.',
      },
      {
        'disease_keyword': 'anthracnose',
        'title': 'Avoid Overhead Irrigation',
        'description':
            'Use ground-level watering to limit splash dispersal of spores on leaves, flowers, and young fruit.',
      },
      {
        'disease_keyword': 'powdery mildew',
        'title': 'Use Sulfur-Based Spray',
        'description':
            'Apply sulfur or other registered mildew fungicides at early bloom and repeat according to label guidance.',
      },
      {
        'disease_keyword': 'powdery mildew',
        'title': 'Lower Humidity Around Leaves',
        'description':
            'Prune to improve light penetration and airflow, especially around panicles and newly flushed shoots.',
      },
      {
        'disease_keyword': 'powdery mildew',
        'title': 'Remove Affected Leaves',
        'description':
            'Remove heavily infected tissues early to lower conidia load during flowering and fruit set.',
      },
      {
        'disease_keyword': 'stem-end rot',
        'title': 'Protect at Harvest',
        'description':
            'Protect fruit in pre-harvest windows and apply approved post-harvest sanitation practices to reduce stem-end infection.',
      },
      {
        'disease_keyword': 'stem-end rot',
        'title': 'Handle Fruits Carefully',
        'description':
            'Minimize stem and peel injury during harvest, grading, and transport to prevent rapid decay.',
      },
      {
        'disease_keyword': 'stem-end rot',
        'title': 'Keep Orchard Clean',
        'description':
            'Remove mummified and fallen fruit regularly to limit fungal carryover in the orchard.',
      },
      {
        'disease_keyword': 'die back',
        'title': 'Prune Beyond Dead Tissue',
        'description':
            'Cut branches below visible dieback margins and burn or bury removed material outside production areas.',
      },
      {
        'disease_keyword': 'die back',
        'title': 'Disinfect Tools',
        'description':
            'Disinfect pruning tools between trees using 70 percent alcohol or approved sanitizer solutions.',
      },
      {
        'disease_keyword': 'die back',
        'title': 'Protect Fresh Wounds',
        'description':
            'Apply approved wound protection on major cuts to reduce pathogen entry after pruning.',
      },
      {
        'disease_keyword': 'canker',
        'title': 'Remove Infected Bark',
        'description':
            'Prune cankered twigs and branches promptly, then sanitize tools and dispose of infected tissue safely.',
      },
      {
        'disease_keyword': 'canker',
        'title': 'Apply Copper Treatment',
        'description':
            'Use registered copper sprays during high-risk periods and after heavy rain if label permits.',
      },
      {
        'disease_keyword': 'canker',
        'title': 'Reduce Plant Stress',
        'description':
            'Maintain balanced nutrition and irrigation to reduce stress that increases canker susceptibility.',
      },
    ];

    for (final item in updates) {
      await db.rawUpdate(
        '''
        UPDATE tbl_action_library
        SET description = ?, updated_at = ?
        WHERE LOWER(TRIM(disease_keyword)) = LOWER(TRIM(?))
          AND LOWER(TRIM(title)) = LOWER(TRIM(?))
        ''',
        [
          item['description']!,
          nowIso,
          item['disease_keyword']!,
          item['title']!,
        ],
      );
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

    // Sanity check + compatibility patching for Pi-provided databases.
    try {
      final db = await openDatabase(destPath);
      try {
        Future<bool> hasTable(String tableName) async {
          final rows = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
            [tableName],
          );
          return rows.isNotEmpty;
        }

        Future<Set<String>> getTableColumns(String tableName) async {
          final rows = await db.rawQuery('PRAGMA table_info($tableName)');
          return rows.map((row) => row['name'] as String).toSet();
        }

        // Check required tables.
        final requiredTables = [
          'tbl_tree',
          'tbl_disease',
          'tbl_severity_level',
          'tbl_scan_record',
        ];
        for (final table in requiredTables) {
          if (!await hasTable(table)) {
            throw Exception('Imported DB missing required table: $table');
          }
        }

        // Patch app-only tables that do not exist in Pi DB exports.
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
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tbl_my_trees(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL UNIQUE,
            location TEXT,
            images TEXT,
            cover_image TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tbl_dataset_folders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            location TEXT NOT NULL DEFAULT '',
            images TEXT NOT NULL,
            date_created TEXT NOT NULL
          )
        ''');

        final datasetFolderCols = await getTableColumns('tbl_dataset_folders');
        if (!datasetFolderCols.contains('location')) {
          await db.execute(
            "ALTER TABLE tbl_dataset_folders ADD COLUMN location TEXT NOT NULL DEFAULT ''",
          );
        }

        // Check essential columns in tbl_scan_record.
        final scanColumnNames = await getTableColumns('tbl_scan_record');
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
        };
        if (!requiredScanColumns.every(scanColumnNames.contains)) {
          throw Exception(
            'Imported DB tbl_scan_record missing essential columns: ${requiredScanColumns.where((c) => !scanColumnNames.contains(c)).join(', ')}',
          );
        }

        // App-side compatibility column used by queries and indexes.
        if (!scanColumnNames.contains('is_archived')) {
          await db.execute(
            'ALTER TABLE tbl_scan_record ADD COLUMN is_archived INTEGER DEFAULT 0',
          );
        }
        await db.execute(
          'UPDATE tbl_scan_record SET is_archived = 0 WHERE is_archived IS NULL',
        );

        // Ensure import/read-path indexes exist in imported DBs.
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_scan_archived ON tbl_scan_record(is_archived)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_scan_archived_timestamp ON tbl_scan_record(is_archived, scan_timestamp DESC)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_photos_photo_id ON tbl_photos(photo_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_photos_name_timestamp ON tbl_photos(name, timestamp)',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS tbl_action_library('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'disease_keyword TEXT NOT NULL,'
          "severity_trigger TEXT NOT NULL DEFAULT 'all',"
          "trend_trigger TEXT NOT NULL DEFAULT 'any',"
          'title TEXT NOT NULL,'
          'description TEXT NOT NULL,'
          'icon_code INTEGER NOT NULL,'
          "color_hex TEXT NOT NULL DEFAULT '#2E7D32',"
          'priority INTEGER NOT NULL DEFAULT 100,'
          'is_active INTEGER NOT NULL DEFAULT 1,'
          'created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,'
          'updated_at TEXT'
          ')',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS tbl_weather_cache('
          'id INTEGER PRIMARY KEY,'
          'latitude REAL NOT NULL,'
          'longitude REAL NOT NULL,'
          'fetched_at TEXT NOT NULL,'
          'temp_c REAL NOT NULL,'
          'humidity_pct REAL NOT NULL,'
          'rainfall_mm REAL NOT NULL,'
          'wind_speed REAL NOT NULL,'
          'condition TEXT NOT NULL,'
          'raw_json TEXT NOT NULL'
          ')',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_action_lookup ON tbl_action_library(disease_keyword, severity_trigger, trend_trigger, is_active, priority)',
        );
        await _seedKnownDiseases(db);
        await _seedActionLibrary(db);
        await _repairScanDiseaseForeignKeys(db);
        await _repairLegacyDatasetFolderImageIds(db);
        await _refreshDefaultActionLibraryContent(db);
        // Stamp the app schema version so _initDb() skips onCreate/onUpgrade
        // when it next opens this imported DB.
        await db.execute('PRAGMA user_version = 8');
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

    await generateDatasetsFromTrees();
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  String _resolvedDiseaseName(ScanItem item) {
    return _canonicalDiseaseName(displayDiseaseName(item, unknownLabel: ''));
  }

  String _resolvedSeverityName(ScanItem item) {
    final normalized = normalizeSeverityLabel(item.severityLevelName);
    if (!isAnthracnoseScan(item)) {
      return 'Not Applicable';
    }

    if (normalized.isNotEmpty) {
      return normalized;
    }

    return statusForScan(item, anthracnoseOnly: false);
  }

  Future<void> upsertScan(ScanItem item) async {
    final db = await database;

    // Upsert tree if data provided
    int? treeId = item.treeId;
    if (treeId != null && item.treeName.isNotEmpty) {
      // Use IGNORE (not REPLACE) — REPLACE does DELETE+INSERT which triggers
      // ON DELETE CASCADE on tbl_scan_record.tree_id and wipes scan records.
      await db.insert('tbl_tree', {
        'id': treeId,
        'name': item.treeName,
        'location': item.treeLocation,
        'variety': item.treeVariety,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.rawUpdate(
        'UPDATE tbl_tree SET name=?, location=?, variety=? WHERE id=?',
        [item.treeName, item.treeLocation, item.treeVariety, treeId],
      );
    }

    // Always resolve disease by canonical name to avoid mismatched foreign keys
    // when imported datasets use a different disease-id namespace.
    int? diseaseId;
    final diseaseName = _resolvedDiseaseName(item);
    if (diseaseName.isNotEmpty) {
      diseaseId = await _ensureDiseaseByName(
        db,
        diseaseName,
        description: item.diseaseDescription,
        symptoms: item.diseaseSymptoms,
        prevention: item.diseasePrevention,
      );
    }

    // Upsert severity level if data provided
    int? severityLevelId = item.severityLevelId;
    final resolvedSeverityName = _resolvedSeverityName(item);
    final shouldReuseProvidedSeverityId =
        isAnthracnoseScan(item) && resolvedSeverityName != 'Not Applicable';
    if (!shouldReuseProvidedSeverityId) {
      severityLevelId = null;
    }

    if (severityLevelId != null && item.severityLevelName.isNotEmpty) {
      await db.insert('tbl_severity_level', {
        'id': severityLevelId,
        'name': item.severityLevelName,
        'description': item.severityLevelDescription,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.rawUpdate(
        'UPDATE tbl_severity_level SET name=?, description=? WHERE id=?',
        [
          item.severityLevelName,
          item.severityLevelDescription,
          severityLevelId,
        ],
      );
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

    if (diseaseId == null && diseaseName.isNotEmpty) {
      diseaseId = await _ensureDiseaseByName(db, diseaseName);
    }

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
        CASE
          WHEN NULLIF(TRIM(d.name), '') IS NOT NULL THEN TRIM(d.name)
          WHEN LOWER(TRIM(COALESCE(r.disease_class, ''))) IN ('imported dataset', 'dataset', 'image detected', 'imported dataset detected', 'dataset detected') THEN ''
          ELSE COALESCE(NULLIF(TRIM(r.disease_class), ''), '')
        END as resolved_disease,
            COALESCE(NULLIF(TRIM(s.name), ''), NULLIF(TRIM(r.severity_level), ''), '') as resolved_severity_name,
            COALESCE(
              CASE
                WHEN TRIM(r.image_path) LIKE '/data/%' OR TRIM(r.image_path) LIKE '/storage/%'
                  THEN NULLIF(TRIM(r.image_path), '')
                ELSE NULL
              END,
              CASE
                WHEN TRIM(r.thumbnail_path) LIKE '/data/%' OR TRIM(r.thumbnail_path) LIKE '/storage/%'
                  THEN NULLIF(TRIM(r.thumbnail_path), '')
                ELSE NULL
              END,
              NULLIF(TRIM((
                SELECT p.path
                FROM tbl_photos p
                WHERE (
                  p.photo_id = r.id OR
                  (p.id = r.id AND (p.photo_id IS NULL OR p.photo_id = r.id))
                )
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
                WHERE (
                  p.photo_id = r.id OR
                  (p.id = r.id AND (p.photo_id IS NULL OR p.photo_id = r.id))
                )
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
    return rows.map(_scanItemFromRow).toList();
  }

  Future<List<ScanItem>> getScansPage({
    required int offset,
    required int limit,
  }) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT r.*, t.name as tree_name, t.location as tree_location, t.variety as tree_variety,
             d.name as disease_name, d.description as disease_description, d.symptoms as disease_symptoms, d.prevention as disease_prevention,
            s.name as severity_name, s.description as severity_description,
        CASE
          WHEN NULLIF(TRIM(d.name), '') IS NOT NULL THEN TRIM(d.name)
          WHEN LOWER(TRIM(COALESCE(r.disease_class, ''))) IN ('imported dataset', 'dataset', 'image detected', 'imported dataset detected', 'dataset detected') THEN ''
          ELSE COALESCE(NULLIF(TRIM(r.disease_class), ''), '')
        END as resolved_disease,
            COALESCE(NULLIF(TRIM(s.name), ''), NULLIF(TRIM(r.severity_level), ''), '') as resolved_severity_name,
            COALESCE(
              CASE
                WHEN TRIM(r.image_path) LIKE '/data/%' OR TRIM(r.image_path) LIKE '/storage/%'
                  THEN NULLIF(TRIM(r.image_path), '')
                ELSE NULL
              END,
              CASE
                WHEN TRIM(r.thumbnail_path) LIKE '/data/%' OR TRIM(r.thumbnail_path) LIKE '/storage/%'
                  THEN NULLIF(TRIM(r.thumbnail_path), '')
                ELSE NULL
              END,
              NULLIF(TRIM((
                SELECT p.path
                FROM tbl_photos p
                WHERE (
                  p.photo_id = r.id OR
                  (p.id = r.id AND (p.photo_id IS NULL OR p.photo_id = r.id))
                )
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
                WHERE (
                  p.photo_id = r.id OR
                  (p.id = r.id AND (p.photo_id IS NULL OR p.photo_id = r.id))
                )
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
      LIMIT ? OFFSET ?
    ''',
      [limit, offset],
    );
    return rows.map(_scanItemFromRow).toList();
  }

  ScanItem _scanItemFromRow(Map<String, Object?> row) {
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
        final name = (row['name']?.toString() ?? '').trim().toLowerCase();
        if (name.isEmpty) continue;
        diseaseCache[name] = row['id'] as int;
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

      final itemIds = items.map((item) => item.id).toList();
      final existingScans = itemIds.isEmpty
          ? <Map<String, Object?>>[]
          : await txn.rawQuery(
              'SELECT id, tree_id, disease_id, disease_class, scan_timestamp, image_path FROM tbl_scan_record '
              'WHERE id IN (${itemIds.map((_) => '?').join(',')})',
              itemIds,
            );
      final existingScanRows = <int, Map<String, Object?>>{
        for (final row in existingScans) row['id'] as int: row,
      };

      for (final item in items) {
        final existing = existingScanRows[item.id];

        // Upsert tree
        // USE IGNORE not REPLACE: REPLACE does DELETE+INSERT which triggers
        // ON DELETE CASCADE on tbl_scan_record.tree_id, cascade-wiping every
        // scan row for that tree already inserted in this transaction.
        int? treeId = item.treeId;
        if (treeId != null && item.treeName.isNotEmpty) {
          await txn.insert('tbl_tree', {
            'id': treeId,
            'name': item.treeName,
            'location': item.treeLocation,
            'variety': item.treeVariety,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          await txn.rawUpdate(
            'UPDATE tbl_tree SET name=?, location=?, variety=? WHERE id=?',
            [item.treeName, item.treeLocation, item.treeVariety, treeId],
          );
          treeCache[item.treeName] = treeId;
        } else if (treeId == null && item.treeName.isNotEmpty) {
          treeId = treeCache[item.treeName];
          if (treeId == null) {
            final insertedId = await txn.insert('tbl_tree', {
              'name': item.treeName,
              'location': item.treeLocation,
              'variety': item.treeVariety,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
            if (insertedId > 0) {
              treeId = insertedId;
            } else {
              final rows = await txn.query(
                'tbl_tree',
                columns: ['id'],
                where: 'name = ?',
                whereArgs: [item.treeName],
                limit: 1,
              );
              treeId = rows.isNotEmpty ? rows.first['id'] as int : null;
            }
            if (treeId != null) treeCache[item.treeName] = treeId;
          }
        }

        // Upsert disease
        final diseaseName = _resolvedDiseaseName(item);
        int? diseaseId;
        if (diseaseName.isNotEmpty) {
          diseaseId = await _ensureDiseaseByName(
            txn,
            diseaseName,
            description: item.diseaseDescription,
            symptoms: item.diseaseSymptoms,
            prevention: item.diseasePrevention,
            cache: diseaseCache,
          );
        }

        treeId ??= existing?['tree_id'] as int?;
        diseaseId ??= existing?['disease_id'] as int?;

        final effectiveDiseaseClass = diseaseName.isNotEmpty
            ? diseaseName
            : (existing?['disease_class'] as String? ?? '');
        final existingTimestamp = existing?['scan_timestamp']?.toString() ?? '';
        final effectiveTimestamp = item.timestamp.isNotEmpty
            ? item.timestamp
            : existingTimestamp;
        final existingImagePath = existing?['image_path']?.toString() ?? '';
        final effectiveImagePath = item.imagePath.isNotEmpty
            ? item.imagePath
            : existingImagePath;

        // Upsert severity level
        final resolvedSeverityName = _resolvedSeverityName(item);
        int? severityLevelId = item.severityLevelId;
        final shouldReuseProvidedSeverityId =
            isAnthracnoseScan(item) && resolvedSeverityName != 'Not Applicable';
        if (!shouldReuseProvidedSeverityId) {
          severityLevelId = null;
        }

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
          'scan_timestamp': effectiveTimestamp,
          'disease_class': effectiveDiseaseClass,
          'confidence_score': item.confidence,
          'severity_percentage': item.severityValue,
          'severity_level': resolvedSeverityName,
          'image_path': effectiveImagePath,
          'source': item.source,
          'analysis_updated_at': item.updatedAt,
          'is_archived': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<ScanSummary> getScanSummary({int? treeId}) async {
    final db = await database;
    final String treeFilter = treeId != null ? 'AND r.tree_id = $treeId' : '';
    final rows = await db.rawQuery('''
      WITH normalized AS (
        SELECT
          LOWER(TRIM(COALESCE(NULLIF(s.name, ''), NULLIF(r.severity_level, ''), ''))) AS severity_text,
          LOWER(TRIM(CASE
            WHEN NULLIF(d.name, '') IS NOT NULL THEN d.name
            WHEN LOWER(TRIM(COALESCE(r.disease_class, ''))) IN ('imported dataset', 'dataset', 'image detected', 'imported dataset detected', 'dataset detected') THEN ''
            ELSE COALESCE(NULLIF(r.disease_class, ''), '')
          END)) AS disease_text,
          COALESCE(r.severity_percentage, 0) AS severity_pct
        FROM tbl_scan_record r
        LEFT JOIN tbl_severity_level s ON r.severity_level_id = s.id
        LEFT JOIN tbl_disease d ON r.disease_id = d.id
        WHERE 1=1 $treeFilter
      ),
      buckets AS (
        SELECT
          CASE
            WHEN disease_text NOT LIKE '%anthracnose%' THEN 'not_applicable'
            WHEN severity_text LIKE '%healthy%' OR disease_text = 'healthy' THEN 'healthy'
            WHEN severity_text = 'high' THEN 'advanced'
            WHEN severity_text LIKE '%advanced%' OR severity_text LIKE '%severe%' OR severity_text LIKE '%critical%' THEN 'advanced'
            WHEN severity_text IN ('low', 'trace') THEN 'early'
            WHEN severity_text LIKE '%early%' OR severity_text LIKE '%moderate%' OR severity_text LIKE '%mid%' THEN 'early'
            WHEN severity_pct > 40.0 THEN 'advanced'
            WHEN severity_pct > 5.0 THEN 'early'
            WHEN disease_text != '' AND disease_text != 'healthy' THEN 'early'
            ELSE 'healthy'
          END AS bucket
        FROM normalized
      )
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN bucket != 'not_applicable' THEN 1 ELSE 0 END) as anthracnose_total,
        SUM(CASE WHEN bucket = 'advanced' THEN 1 ELSE 0 END) as advanced_stage,
        SUM(CASE WHEN bucket = 'early' THEN 1 ELSE 0 END) as early_stage,
        SUM(CASE WHEN bucket = 'healthy' THEN 1 ELSE 0 END) as healthy
      FROM buckets
    ''');

    if (rows.isEmpty) {
      return ScanSummary(
        totalScans: 0,
        anthracnoseTotal: 0,
        healthyCount: 0,
        earlyStageCount: 0,
        advancedStageCount: 0,
      );
    }

    final row = rows.first;
    return ScanSummary(
      totalScans: row['total'] as int? ?? 0,
      anthracnoseTotal: row['anthracnose_total'] as int? ?? 0,
      healthyCount: row['healthy'] as int? ?? 0,
      earlyStageCount: row['early_stage'] as int? ?? 0,
      advancedStageCount: row['advanced_stage'] as int? ?? 0,
    );
  }

  Future<OrchardSnapshot> getOrchardSnapshot({int? treeId}) async {
    final results = await Future.wait([
      getScanSummary(treeId: treeId),
      getDiseaseDistribution(treeId: treeId),
      getAnthracnoseStageSummary(treeId: treeId),
      getDiseaseWeeklyTrendSeries(
        diseaseKeyword: 'anthracnose',
        treeId: treeId,
      ),
      getPrimaryDiseaseName(treeId: treeId),
      getLatestScanDate(treeId: treeId),
      getScanRowCompleteness(),
    ]);

    return OrchardSnapshot(
      summary: results[0] as ScanSummary,
      diseaseDistributionRows: results[1] as List<Map<String, dynamic>>,
      anthracnoseStageSummary: results[2] as Map<String, int>,
      anthracnoseTrendSeries: results[3] as List<Map<String, dynamic>>,
      primaryDisease: results[4] as String,
      latestScanDate: results[5] as String?,
      rowCompleteness: results[6] as Map<String, int>,
    );
  }

  Future<List<double>> getWeeklyTrend({int? treeId}) async {
    final rows = await getWeeklyTrendSeries(treeId: treeId);
    return rows.map((row) => (row['count'] as int).toDouble()).toList();
  }

  Future<List<Map<String, dynamic>>> getWeeklyTrendSeries({int? treeId}) async {
    final db = await database;
    final String treeFilter = treeId != null ? 'AND tree_id = $treeId' : '';
    final rows = await db.rawQuery('''
      WITH normalized AS (
        SELECT
          datetime(replace(replace(substr(scan_timestamp, 1, 19), 'T', ' '), 'Z', '')) AS normalized_ts
        FROM tbl_scan_record
        WHERE scan_timestamp IS NOT NULL AND TRIM(scan_timestamp) != '' $treeFilter
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

    final List<Map<String, dynamic>> series = [];
    for (final row in rows.reversed) {
      final weekRaw = row['week']?.toString() ?? '';
      final count = row['count'] as int? ?? 0;
      series.add({
        'week': weekRaw,
        'count': count,
        'label': _weekLabelFromYearWeek(weekRaw),
      });
    }
    return series;
  }

  String _weekLabelFromYearWeek(String yearWeek) {
    final parts = yearWeek.split('-');
    if (parts.length != 2) return yearWeek;

    final year = int.tryParse(parts[0]);
    final week = int.tryParse(parts[1]);
    if (year == null || week == null) return yearWeek;

    final jan1 = DateTime(year, 1, 1);
    final firstMondayOffset = (DateTime.monday - jan1.weekday + 7) % 7;
    final DateTime weekStart;
    if (week <= 0) {
      weekStart = jan1;
    } else {
      final firstMonday = jan1.add(Duration(days: firstMondayOffset));
      weekStart = firstMonday.add(Duration(days: (week - 1) * 7));
    }
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[weekStart.month - 1]} ${weekStart.day}';
  }

  Future<String?> getLatestScanDate({int? treeId}) async {
    final db = await database;
    final String treeFilter = treeId != null ? 'AND tree_id = $treeId' : '';
    final rows = await db.rawQuery('''
      WITH normalized AS (
        SELECT datetime(replace(replace(substr(scan_timestamp, 1, 19), 'T', ' '), 'Z', '')) AS normalized_ts
        FROM tbl_scan_record
        WHERE scan_timestamp IS NOT NULL AND TRIM(scan_timestamp) != '' $treeFilter
      )
      SELECT MAX(normalized_ts) AS latest
      FROM normalized
      WHERE normalized_ts IS NOT NULL
    ''');

    if (rows.isEmpty) return null;
    return rows.first['latest'] as String?;
  }

  Future<Map<String, int>> getScanRowCompleteness() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) AS total,
        SUM(
          CASE
            WHEN scan_timestamp IS NULL OR TRIM(scan_timestamp) = ''
              OR COALESCE(NULLIF(TRIM(disease_class), ''), '') = ''
              OR COALESCE(confidence_score, -1) < 0
              OR COALESCE(severity_percentage, -1) < 0
            THEN 1
            ELSE 0
          END
        ) AS incomplete
      FROM tbl_scan_record
    ''');

    if (rows.isEmpty) {
      return {'total': 0, 'incomplete': 0};
    }

    final row = rows.first;
    return {
      'total': row['total'] as int? ?? 0,
      'incomplete': row['incomplete'] as int? ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getDistinctTreesWithScans() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT DISTINCT t.id, t.name
      FROM tbl_tree t
      INNER JOIN tbl_scan_record r ON r.tree_id = t.id
      WHERE t.name IS NOT NULL AND TRIM(t.name) != ''
      ORDER BY t.name COLLATE NOCASE ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getDiseaseDistribution({
    int? treeId,
  }) async {
    final db = await database;
    final String treeFilter = treeId != null ? 'AND r.tree_id = $treeId' : '';
    final rows = await db.rawQuery('''
      WITH normalized AS (
        SELECT
          CASE
            WHEN NULLIF(TRIM(d.name), '') IS NOT NULL THEN TRIM(d.name)
            WHEN LOWER(TRIM(COALESCE(r.disease_class, ''))) IN ('imported dataset', 'dataset', 'image detected', 'imported dataset detected', 'dataset detected') THEN ''
            ELSE COALESCE(NULLIF(TRIM(r.disease_class), ''), '')
          END AS disease_name,
          LOWER(TRIM(COALESCE(NULLIF(s.name, ''), NULLIF(r.severity_level, ''), ''))) AS severity_text,
          CASE
            WHEN NULLIF(TRIM(d.name), '') IS NOT NULL THEN TRIM(d.name)
            WHEN LOWER(TRIM(COALESCE(r.disease_class, ''))) IN ('imported dataset', 'dataset', 'image detected', 'imported dataset detected', 'dataset detected') THEN ''
            ELSE COALESCE(NULLIF(TRIM(r.disease_class), ''), '')
          END AS disease,
          LOWER(TRIM(CASE
            WHEN NULLIF(TRIM(d.name), '') IS NOT NULL THEN TRIM(d.name)
            WHEN LOWER(TRIM(COALESCE(r.disease_class, ''))) IN ('imported dataset', 'dataset', 'image detected', 'imported dataset detected', 'dataset detected') THEN ''
            ELSE COALESCE(NULLIF(TRIM(r.disease_class), ''), '')
          END)) AS disease_text,
          COALESCE(r.severity_percentage, 0) AS severity_pct
        FROM tbl_scan_record r
        LEFT JOIN tbl_disease d ON r.disease_id = d.id
        LEFT JOIN tbl_severity_level s ON r.severity_level_id = s.id
        WHERE 1=1 $treeFilter
      ),
      bucketed AS (
        SELECT
          CASE
            WHEN severity_text LIKE '%healthy%' OR disease_text = 'healthy' THEN 'Healthy'
            WHEN severity_text = 'high' THEN COALESCE(NULLIF(disease_name, ''), 'Unknown')
            WHEN severity_text LIKE '%advanced%' OR severity_text LIKE '%severe%' OR severity_text LIKE '%critical%' THEN COALESCE(NULLIF(disease_name, ''), 'Unknown')
            WHEN severity_text IN ('low', 'trace') THEN COALESCE(NULLIF(disease_name, ''), 'Unknown')
            WHEN severity_text LIKE '%early%' OR severity_text LIKE '%moderate%' OR severity_text LIKE '%mid%' THEN COALESCE(NULLIF(disease_name, ''), 'Unknown')
            WHEN severity_pct > 40.0 THEN COALESCE(NULLIF(disease_name, ''), 'Unknown')
            WHEN severity_pct > 5.0 THEN COALESCE(NULLIF(disease_name, ''), 'Unknown')
            WHEN disease_text != '' AND disease_text != 'healthy' THEN COALESCE(NULLIF(disease_name, ''), 'Unknown')
            ELSE 'Healthy'
          END AS disease
        FROM normalized
      )
      SELECT
        disease,
        COUNT(*) AS count
      FROM bucketed
      GROUP BY disease
      ORDER BY count DESC
    ''');
    return rows;
  }

  Future<String> getPrimaryDiseaseName({int? treeId}) async {
    final db = await database;
    final String treeFilter = treeId != null ? 'AND r.tree_id = $treeId' : '';
    final rows = await db.rawQuery('''
      WITH normalized AS (
        SELECT
          CASE
            WHEN NULLIF(TRIM(d.name), '') IS NOT NULL THEN TRIM(d.name)
            WHEN LOWER(TRIM(COALESCE(r.disease_class, ''))) IN ('imported dataset', 'dataset', 'image detected', 'imported dataset detected', 'dataset detected') THEN ''
            ELSE COALESCE(NULLIF(TRIM(r.disease_class), ''), '')
          END AS disease
        FROM tbl_scan_record r
        LEFT JOIN tbl_disease d ON r.disease_id = d.id
        WHERE 1=1 $treeFilter
      )
      SELECT disease, COUNT(*) AS count
      FROM normalized
      WHERE LOWER(disease) NOT IN ('healthy', 'unknown', '')
      GROUP BY disease
      ORDER BY count DESC
      LIMIT 1
    ''');
    if (rows.isEmpty) return 'No Active Disease';
    return rows.first['disease']?.toString() ?? 'No Active Disease';
  }

  Future<int> getAnthracnoseCount({int? treeId}) async {
    final db = await database;
    final String treeFilter = treeId != null ? 'AND r.tree_id = $treeId' : '';
    final rows = await db.rawQuery('''
      WITH normalized AS (
        SELECT
          LOWER(TRIM(CASE
            WHEN NULLIF(TRIM(d.name), '') IS NOT NULL THEN d.name
            WHEN LOWER(TRIM(COALESCE(r.disease_class, ''))) IN ('imported dataset', 'dataset', 'image detected', 'imported dataset detected', 'dataset detected') THEN ''
            ELSE COALESCE(NULLIF(TRIM(r.disease_class), ''), '')
          END)) AS disease
        FROM tbl_scan_record r
        LEFT JOIN tbl_disease d ON r.disease_id = d.id
        WHERE 1=1 $treeFilter
      )
      SELECT COUNT(*) AS count
      FROM normalized
      WHERE disease LIKE '%anthracnose%'
    ''');

    if (rows.isEmpty) return 0;
    final value = rows.first['count'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<Map<String, int>> getAnthracnoseStageSummary({int? treeId}) async {
    final db = await database;
    final String treeFilter = treeId != null ? 'AND r.tree_id = $treeId' : '';
    final rows = await db.rawQuery('''
      WITH normalized AS (
        SELECT
          LOWER(TRIM(CASE
            WHEN NULLIF(TRIM(d.name), '') IS NOT NULL THEN TRIM(d.name)
            WHEN LOWER(TRIM(COALESCE(r.disease_class, ''))) IN ('imported dataset', 'dataset', 'image detected', 'imported dataset detected', 'dataset detected') THEN ''
            ELSE COALESCE(NULLIF(TRIM(r.disease_class), ''), '')
          END)) AS disease_text,
          LOWER(TRIM(COALESCE(NULLIF(s.name, ''), NULLIF(r.severity_level, ''), ''))) AS severity_text,
          COALESCE(r.severity_percentage, 0) AS severity_pct
        FROM tbl_scan_record r
        LEFT JOIN tbl_disease d ON r.disease_id = d.id
        LEFT JOIN tbl_severity_level s ON r.severity_level_id = s.id
        WHERE 1=1 $treeFilter
      ),
      anthracnose_only AS (
        SELECT *
        FROM normalized
        WHERE disease_text LIKE '%anthracnose%'
      ),
      bucketed AS (
        SELECT
          CASE
            WHEN severity_text LIKE '%healthy%' THEN 'healthy'
            WHEN severity_text = 'high' THEN 'advanced'
            WHEN severity_text LIKE '%advanced%' OR severity_text LIKE '%severe%' OR severity_text LIKE '%critical%' THEN 'advanced'
            WHEN severity_text IN ('low', 'trace') THEN 'early'
            WHEN severity_text LIKE '%early%' OR severity_text LIKE '%moderate%' OR severity_text LIKE '%mid%' THEN 'early'
            WHEN severity_pct > 40.0 THEN 'advanced'
            WHEN severity_pct > 5.0 THEN 'early'
            ELSE 'healthy'
          END AS severity_bucket
        FROM anthracnose_only
      )
      SELECT
        SUM(CASE WHEN severity_bucket = 'healthy' THEN 1 ELSE 0 END) AS healthy_count,
        SUM(CASE WHEN severity_bucket = 'early' THEN 1 ELSE 0 END) AS early_count,
        SUM(CASE WHEN severity_bucket = 'advanced' THEN 1 ELSE 0 END) AS advanced_count,
        COUNT(*) AS total_count
      FROM bucketed
    ''');

    int toIntValue(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    if (rows.isEmpty) {
      return {'healthy': 0, 'early': 0, 'advanced': 0, 'total': 0};
    }

    final row = rows.first;
    return {
      'healthy': toIntValue(row['healthy_count']),
      'early': toIntValue(row['early_count']),
      'advanced': toIntValue(row['advanced_count']),
      'total': toIntValue(row['total_count']),
    };
  }

  Future<List<Map<String, dynamic>>> getDiseaseWeeklyTrendSeries({
    required String diseaseKeyword,
    int? treeId,
  }) async {
    final db = await database;
    final String treeFilter = treeId != null ? 'AND r.tree_id = $treeId' : '';
    final String normalizedKeyword = diseaseKeyword.trim().toLowerCase();

    final rows = await db.rawQuery(
      '''
      WITH normalized AS (
        SELECT
          datetime(replace(replace(substr(r.scan_timestamp, 1, 19), 'T', ' '), 'Z', '')) AS normalized_ts,
          LOWER(TRIM(CASE
            WHEN NULLIF(TRIM(d.name), '') IS NOT NULL THEN d.name
            WHEN LOWER(TRIM(COALESCE(r.disease_class, ''))) IN ('imported dataset', 'dataset', 'image detected', 'imported dataset detected', 'dataset detected') THEN ''
            ELSE COALESCE(NULLIF(TRIM(r.disease_class), ''), '')
          END)) AS disease
        FROM tbl_scan_record r
        LEFT JOIN tbl_disease d ON r.disease_id = d.id
        WHERE r.scan_timestamp IS NOT NULL
          AND TRIM(r.scan_timestamp) != ''
          $treeFilter
      )
      SELECT
        strftime('%Y-%W', normalized_ts) as week,
        COUNT(*) as count
      FROM normalized
      WHERE normalized_ts IS NOT NULL
        AND disease LIKE ?
      GROUP BY week
      ORDER BY week DESC
      LIMIT 11
    ''',
      ['%$normalizedKeyword%'],
    );

    final List<Map<String, dynamic>> series = [];
    for (final row in rows.reversed) {
      final weekRaw = row['week']?.toString() ?? '';
      final count = row['count'] as int? ?? 0;
      series.add({
        'week': weekRaw,
        'count': count,
        'label': _weekLabelFromYearWeek(weekRaw),
      });
    }
    return series;
  }

  Future<List<Map<String, dynamic>>> getSeverityTrendMonthOptions({
    int? treeId,
  }) async {
    final db = await database;
    final String treeFilter = treeId != null ? 'AND r.tree_id = ?' : '';
    final args = <Object?>[];
    if (treeId != null) args.add(treeId);

    final rows = await db.rawQuery('''
      SELECT r.scan_timestamp, r.analysis_updated_at
      FROM tbl_scan_record r
      WHERE (
          (r.scan_timestamp IS NOT NULL AND TRIM(r.scan_timestamp) != '')
          OR (r.analysis_updated_at IS NOT NULL AND TRIM(r.analysis_updated_at) != '')
        )
        $treeFilter
    ''', args);

    final Set<int> uniqueMonthKeys = <int>{};
    for (final row in rows) {
      final raw = row['scan_timestamp']?.toString() ?? '';
      final fallbackRaw = row['analysis_updated_at']?.toString() ?? '';
      final parsed = _parseTrendTimestamp(raw, fallbackRaw: fallbackRaw);
      if (parsed == null) continue;
      uniqueMonthKeys.add(parsed.year * 100 + parsed.month);
    }

    final sorted = uniqueMonthKeys.toList()..sort((a, b) => b.compareTo(a));
    return sorted
        .map((key) {
          final year = key ~/ 100;
          final month = key % 100;
          return {
            'year': year,
            'month': month,
            'label': _monthLabel(month, year),
          };
        })
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getSeverityProgressionSeries({
    int? treeId,
    int? month,
    int? year,
    int weekWindow = 8,
  }) async {
    final db = await database;
    final String treeFilter = treeId != null ? 'AND r.tree_id = ?' : '';
    final args = <Object?>[];
    if (treeId != null) args.add(treeId);

    final rows = await db.rawQuery('''
      SELECT
        r.scan_timestamp,
        r.analysis_updated_at,
        COALESCE(NULLIF(TRIM(s.name), ''), NULLIF(TRIM(r.severity_level), ''), '') AS severity_text,
        LOWER(TRIM(CASE
          WHEN NULLIF(TRIM(d.name), '') IS NOT NULL THEN TRIM(d.name)
          WHEN LOWER(TRIM(COALESCE(r.disease_class, ''))) IN ('imported dataset', 'dataset', 'image detected', 'imported dataset detected', 'dataset detected') THEN ''
          ELSE COALESCE(NULLIF(TRIM(r.disease_class), ''), '')
        END)) AS disease_text,
        COALESCE(r.severity_percentage, 0) AS severity_pct
      FROM tbl_scan_record r
      LEFT JOIN tbl_disease d ON r.disease_id = d.id
      LEFT JOIN tbl_severity_level s ON r.severity_level_id = s.id
      WHERE (
          (r.scan_timestamp IS NOT NULL AND TRIM(r.scan_timestamp) != '')
          OR (r.analysis_updated_at IS NOT NULL AND TRIM(r.analysis_updated_at) != '')
        )
        $treeFilter
    ''', args);

    final Map<DateTime, _SeverityBucketCounter> weeklyBuckets =
        <DateTime, _SeverityBucketCounter>{};

    for (final row in rows) {
      final parsed = _parseTrendTimestamp(
        row['scan_timestamp']?.toString() ?? '',
        fallbackRaw: row['analysis_updated_at']?.toString() ?? '',
      );
      if (parsed == null) continue;

      if (month != null && year != null) {
        if (parsed.month != month || parsed.year != year) {
          continue;
        }
      }

      final bucket = _resolveSeverityBucket(
        severityText: row['severity_text']?.toString() ?? '',
        diseaseText: row['disease_text']?.toString() ?? '',
        severityPercent: (row['severity_pct'] as num?)?.toDouble() ?? 0,
      );

      if (bucket == 'not_applicable') {
        continue;
      }

      final weekStart = _startOfWeek(parsed);
      final counter = weeklyBuckets.putIfAbsent(
        weekStart,
        () => _SeverityBucketCounter(),
      );

      switch (bucket) {
        case 'healthy':
          counter.healthy += 1;
          break;
        case 'early':
          counter.early += 1;
          break;
        case 'advanced':
          counter.advanced += 1;
          break;
      }
    }

    if (weeklyBuckets.isEmpty) return <Map<String, dynamic>>[];

    final List<DateTime> weeks = weeklyBuckets.keys.toList()..sort();
    late final List<DateTime> selectedWeeks;

    if (month != null && year != null) {
      final start = weeks.length > weekWindow ? weeks.length - weekWindow : 0;
      selectedWeeks = weeks.sublist(start);
    } else {
      final latest = weeks.last;
      selectedWeeks = List<DateTime>.generate(
        weekWindow,
        (index) =>
            latest.subtract(Duration(days: (weekWindow - 1 - index) * 7)),
      );
    }

    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    for (final week in selectedWeeks) {
      final counter = weeklyBuckets[week] ?? _SeverityBucketCounter();
      final total = counter.total;

      final healthyPct = total <= 0 ? 0.0 : (counter.healthy / total) * 100;
      final earlyPct = total <= 0 ? 0.0 : (counter.early / total) * 100;
      final advancedPct = total <= 0 ? 0.0 : (counter.advanced / total) * 100;

      result.add({
        'week_start': week.toIso8601String(),
        'label': _weekLabelFromDate(week),
        'healthy': healthyPct,
        'early': earlyPct,
        'advanced': advancedPct,
        'total': total,
      });
    }

    return result;
  }

  DateTime _startOfWeek(DateTime dt) {
    final normalized = DateTime.utc(dt.year, dt.month, dt.day);
    return normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
  }

  DateTime? _parseTrendTimestamp(String raw, {String? fallbackRaw}) {
    final trimmed = raw.trim().isNotEmpty
        ? raw.trim()
        : (fallbackRaw ?? '').trim();
    if (trimmed.isEmpty) return null;

    final parsed =
        DateTime.tryParse(trimmed) ??
        DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
    if (parsed != null) return parsed;

    final m = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2}):(\d{2}))?',
    ).firstMatch(trimmed);
    if (m == null) return null;

    final y = int.tryParse(m.group(1) ?? '');
    final mo = int.tryParse(m.group(2) ?? '');
    final d = int.tryParse(m.group(3) ?? '');
    final h = int.tryParse(m.group(4) ?? '0');
    final mi = int.tryParse(m.group(5) ?? '0');
    final s = int.tryParse(m.group(6) ?? '0');

    if (y == null || mo == null || d == null) return null;
    return DateTime(y, mo, d, h ?? 0, mi ?? 0, s ?? 0);
  }

  String _resolveSeverityBucket({
    required String severityText,
    required String diseaseText,
    required double severityPercent,
  }) {
    final severity = severityText.trim().toLowerCase();
    final disease = diseaseText.trim().toLowerCase();

    if (!disease.contains('anthracnose')) return 'not_applicable';

    if (severity.contains('healthy') || disease == 'healthy') return 'healthy';
    if (severity == 'high') return 'advanced';
    if (severity.contains('advanced') ||
        severity.contains('severe') ||
        severity.contains('critical')) {
      return 'advanced';
    }
    if (severity == 'low' || severity == 'trace') return 'early';
    if (severity.contains('early') ||
        severity.contains('moderate') ||
        severity.contains('mid')) {
      return 'early';
    }
    if (severityPercent > 40.0) return 'advanced';
    if (severityPercent > 5.0) return 'early';
    if (disease.isNotEmpty && disease != 'healthy') return 'early';
    return 'healthy';
  }

  String _weekLabelFromDate(DateTime weekStart) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[weekStart.month - 1]} ${weekStart.day}';
  }

  String _monthLabel(int month, int year) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '$month/$year';
    return '${monthNames[month - 1]} $year';
  }

  Future<List<ActionItem>> getAllActions() async {
    final db = await database;
    final rows = await db.query(
      'tbl_action_library',
      where: 'is_active = 1',
      orderBy: 'disease_keyword COLLATE NOCASE ASC, priority ASC, id ASC',
    );
    return rows.map(ActionItem.fromMap).toList(growable: false);
  }

  Future<List<ActionItem>> getActionsForContext({
    required String disease,
    required String severityTrigger,
    required String trendTrigger,
  }) async {
    final db = await database;
    final normalizedDisease = disease.trim().toLowerCase();
    final normalizedSeverity = severityTrigger.trim().toLowerCase();
    final normalizedTrend = trendTrigger.trim().toLowerCase();

    final rows = await db.rawQuery(
      '''
      SELECT *
      FROM tbl_action_library
      WHERE is_active = 1
        AND (disease_keyword = ? OR disease_keyword = 'default')
        AND (severity_trigger = ? OR severity_trigger = 'all')
        AND (trend_trigger = ? OR trend_trigger = 'any')
      ORDER BY
        CASE WHEN disease_keyword = ? THEN 0 ELSE 1 END,
        CASE WHEN severity_trigger = ? THEN 0 ELSE 1 END,
        CASE WHEN trend_trigger = ? THEN 0 ELSE 1 END,
        priority ASC,
        id ASC
      ''',
      [
        normalizedDisease,
        normalizedSeverity,
        normalizedTrend,
        normalizedDisease,
        normalizedSeverity,
        normalizedTrend,
      ],
    );

    return rows.map(ActionItem.fromMap).toList(growable: false);
  }

  Future<int> upsertAction(ActionItem item) async {
    final db = await database;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final map = item.toMap()..['updated_at'] = nowIso;

    if (item.id == null) {
      map['created_at'] = nowIso;
      return db.insert('tbl_action_library', map);
    }

    await db.update(
      'tbl_action_library',
      map,
      where: 'id = ?',
      whereArgs: [item.id],
    );
    return item.id!;
  }

  Future<void> deleteAction(int id) async {
    final db = await database;
    await db.delete('tbl_action_library', where: 'id = ?', whereArgs: [id]);
  }

  Future<WeatherData?> getCachedWeather() async {
    final db = await database;
    final rows = await db.query('tbl_weather_cache', where: 'id = 1', limit: 1);
    if (rows.isEmpty) {
      return null;
    }
    return WeatherData.fromMap(rows.first);
  }

  Future<void> saveWeatherCache(WeatherData weather) async {
    final db = await database;
    await db.insert(
      'tbl_weather_cache',
      weather.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _seedActionLibrary(Database db) async {
    final existing = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM tbl_action_library',
    );
    final existingCount = (existing.first['count'] as int?) ?? 0;
    if (existingCount > 0) {
      return;
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final seeds = <ActionItem>[
      const ActionItem(
        diseaseKeyword: 'default',
        severityTrigger: 'all',
        trendTrigger: 'any',
        title: 'Apply Fungicide',
        description:
            'During wet conditions, apply a labeled protectant spray such as copper hydroxide or mancozeb and follow local pre-harvest intervals.',
        iconCode: 0xe3bb,
        colorHex: '#06850C',
        priority: 10,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'default',
        severityTrigger: 'all',
        trendTrigger: 'any',
        title: 'Improve Drainage',
        description:
            'Keep root zones free from standing water and clear drainage canals before heavy rain periods.',
        iconCode: 0xebde,
        colorHex: '#85D133',
        priority: 20,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'default',
        severityTrigger: 'all',
        trendTrigger: 'any',
        title: 'Remove Infected Leaves',
        description:
            'Collect and destroy infected leaves, twigs, and fruit debris to reduce inoculum between flushes.',
        iconCode: 0xe16c,
        colorHex: '#A5E358',
        priority: 30,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'anthracnose',
        severityTrigger: 'early',
        trendTrigger: 'worsening',
        title: 'Targeted Fungicide Spray',
        description:
          'Start preventive copper or mancozeb sprays at flowering and repeat at label intervals when rainfall and humidity remain high.',
        iconCode: 0xe3bb,
        colorHex: '#06850C',
        priority: 1,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'anthracnose',
        severityTrigger: 'advanced',
        trendTrigger: 'any',
        title: 'Prune Infected Growth',
        description:
          'Prune visibly infected twigs 10-15 cm below lesions and destroy cuttings away from productive blocks.',
        iconCode: 0xe3c9,
        colorHex: '#2E7D32',
        priority: 2,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'anthracnose',
        severityTrigger: 'all',
        trendTrigger: 'any',
        title: 'Improve Air Flow',
        description:
          'Open dense canopy sections to shorten leaf wetness duration and reduce anthracnose infection pressure.',
        iconCode: 0xe3a7,
        colorHex: '#85D133',
        priority: 3,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'anthracnose',
        severityTrigger: 'all',
        trendTrigger: 'any',
        title: 'Avoid Overhead Irrigation',
        description:
          'Use ground-level watering to limit splash dispersal of spores on leaves, flowers, and young fruit.',
        iconCode: 0xebde,
        colorHex: '#A5E358',
        priority: 4,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'powdery mildew',
        severityTrigger: 'early',
        trendTrigger: 'worsening',
        title: 'Use Sulfur-Based Spray',
        description:
          'Apply sulfur or other registered mildew fungicides at early bloom and repeat according to label guidance.',
        iconCode: 0xe3bb,
        colorHex: '#06850C',
        priority: 1,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'powdery mildew',
        severityTrigger: 'all',
        trendTrigger: 'any',
        title: 'Lower Humidity Around Leaves',
        description:
          'Prune to improve light penetration and airflow, especially around panicles and newly flushed shoots.',
        iconCode: 0xe3a7,
        colorHex: '#85D133',
        priority: 2,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'powdery mildew',
        severityTrigger: 'all',
        trendTrigger: 'any',
        title: 'Remove Affected Leaves',
        description:
            'Remove heavily infected tissues early to lower conidia load during flowering and fruit set.',
        iconCode: 0xe16c,
        colorHex: '#A5E358',
        priority: 3,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'stem-end rot',
        severityTrigger: 'all',
        trendTrigger: 'worsening',
        title: 'Protect at Harvest',
        description:
          'Protect fruit in pre-harvest windows and apply approved post-harvest sanitation practices to reduce stem-end infection.',
        iconCode: 0xe3bb,
        colorHex: '#06850C',
        priority: 1,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'stem-end rot',
        severityTrigger: 'all',
        trendTrigger: 'any',
        title: 'Handle Fruits Carefully',
        description:
          'Minimize stem and peel injury during harvest, grading, and transport to prevent rapid decay.',
        iconCode: 0xe553,
        colorHex: '#85D133',
        priority: 2,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'stem-end rot',
        severityTrigger: 'all',
        trendTrigger: 'any',
        title: 'Keep Orchard Clean',
        description:
            'Remove mummified and fallen fruit regularly to limit fungal carryover in the orchard.',
        iconCode: 0xe56d,
        colorHex: '#A5E358',
        priority: 3,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'die back',
        severityTrigger: 'advanced',
        trendTrigger: 'any',
        title: 'Prune Beyond Dead Tissue',
        description:
            'Cut branches below visible dieback margins and burn or bury removed material outside production areas.',
        iconCode: 0xe3c9,
        colorHex: '#06850C',
        priority: 1,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'die back',
        severityTrigger: 'all',
        trendTrigger: 'any',
        title: 'Disinfect Tools',
        description:
          'Disinfect pruning tools between trees using 70 percent alcohol or approved sanitizer solutions.',
        iconCode: 0xf0554,
        colorHex: '#85D133',
        priority: 2,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'die back',
        severityTrigger: 'all',
        trendTrigger: 'any',
        title: 'Protect Fresh Wounds',
        description:
            'Apply approved wound protection on major cuts to reduce pathogen entry after pruning.',
        iconCode: 0xe9e0,
        colorHex: '#A5E358',
        priority: 3,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'canker',
        severityTrigger: 'advanced',
        trendTrigger: 'any',
        title: 'Remove Infected Bark',
        description:
            'Prune cankered twigs and branches promptly, then sanitize tools and dispose of infected tissue safely.',
        iconCode: 0xe16c,
        colorHex: '#06850C',
        priority: 1,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'canker',
        severityTrigger: 'early',
        trendTrigger: 'worsening',
        title: 'Apply Copper Treatment',
        description:
            'Use registered copper sprays during high-risk periods and after heavy rain if label permits.',
        iconCode: 0xe3bb,
        colorHex: '#85D133',
        priority: 2,
        isActive: true,
      ),
      const ActionItem(
        diseaseKeyword: 'canker',
        severityTrigger: 'all',
        trendTrigger: 'any',
        title: 'Reduce Plant Stress',
        description:
          'Maintain balanced nutrition and irrigation to reduce stress that increases canker susceptibility.',
        iconCode: 0xe3f9,
        colorHex: '#A5E358',
        priority: 3,
        isActive: true,
      ),
    ];

    final batch = db.batch();
    for (final seed in seeds) {
      final row = seed.toMap();
      row['created_at'] = nowIso;
      row['updated_at'] = nowIso;
      batch.insert('tbl_action_library', row);
    }
    await batch.commit(noResult: true);
  }

  Future<ScanItem?> getScanById(int id) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT r.*, t.name as tree_name, t.location as tree_location, t.variety as tree_variety,
             d.name as disease_name, d.description as disease_description, d.symptoms as disease_symptoms, d.prevention as disease_prevention,
            s.name as severity_name, s.description as severity_description,
            CASE
              WHEN NULLIF(TRIM(d.name), '') IS NOT NULL THEN TRIM(d.name)
              WHEN LOWER(TRIM(COALESCE(r.disease_class, ''))) IN ('imported dataset', 'dataset', 'image detected', 'imported dataset detected', 'dataset detected') THEN ''
              ELSE COALESCE(NULLIF(TRIM(r.disease_class), ''), '')
            END as resolved_disease,
        COALESCE(NULLIF(TRIM(s.name), ''), NULLIF(TRIM(r.severity_level), ''), '') as resolved_severity_name,
        COALESCE(
          CASE
            WHEN TRIM(r.image_path) LIKE '/data/%' OR TRIM(r.image_path) LIKE '/storage/%'
              THEN NULLIF(TRIM(r.image_path), '')
            ELSE NULL
          END,
          CASE
            WHEN TRIM(r.thumbnail_path) LIKE '/data/%' OR TRIM(r.thumbnail_path) LIKE '/storage/%'
              THEN NULLIF(TRIM(r.thumbnail_path), '')
            ELSE NULL
          END,
          NULLIF(TRIM((
            SELECT p.path
            FROM tbl_photos p
            WHERE (
              p.photo_id = r.id OR
              (p.id = r.id AND (p.photo_id IS NULL OR p.photo_id = r.id))
            )
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
            WHERE (
              p.photo_id = r.id OR
              (p.id = r.id AND (p.photo_id IS NULL OR p.photo_id = r.id))
            )
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
            CASE
              WHEN TRIM(r.image_path) LIKE '/data/%' OR TRIM(r.image_path) LIKE '/storage/%'
                THEN NULLIF(TRIM(r.image_path), '')
              ELSE NULL
            END,
            CASE
              WHEN TRIM(r.thumbnail_path) LIKE '/data/%' OR TRIM(r.thumbnail_path) LIKE '/storage/%'
                THEN NULLIF(TRIM(r.thumbnail_path), '')
              ELSE NULL
            END,
            NULLIF(TRIM((
              SELECT p.path
              FROM tbl_photos p
              WHERE (
                p.photo_id = r.id OR
                (p.id = r.id AND (p.photo_id IS NULL OR p.photo_id = r.id))
              )
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
              WHERE (
                p.photo_id = r.id OR
                (p.id = r.id AND (p.photo_id IS NULL OR p.photo_id = r.id))
              )
                AND p.image_url IS NOT NULL
                AND TRIM(p.image_url) != ''
              ORDER BY p.id DESC
              LIMIT 1
            )), ''),
            ''
          ) as image_url,
          r.confidence_score as confidence,
          r.severity_percentage as severity_value,
          COALESCE(NULLIF(TRIM(s.name), ''), NULLIF(TRIM(r.severity_level), ''), '') as severity_label,
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
          CASE
            WHEN TRIM(image_path) LIKE '/data/%' OR TRIM(image_path) LIKE '/storage/%'
              THEN NULLIF(TRIM(image_path), '')
            ELSE NULL
          END,
          CASE
            WHEN TRIM(thumbnail_path) LIKE '/data/%' OR TRIM(thumbnail_path) LIKE '/storage/%'
              THEN NULLIF(TRIM(thumbnail_path), '')
            ELSE NULL
          END
        ) AS image_path,
        NULLIF(TRIM((
          SELECT p.image_url
          FROM tbl_photos p
          WHERE (
            p.photo_id = tbl_scan_record.id OR
            (p.id = tbl_scan_record.id AND (p.photo_id IS NULL OR p.photo_id = tbl_scan_record.id))
          )
            AND p.image_url IS NOT NULL
            AND TRIM(p.image_url) != ''
          ORDER BY p.id DESC
          LIMIT 1
        )), '') AS image_url
      FROM tbl_scan_record
      WHERE COALESCE(
        CASE
          WHEN TRIM(image_path) LIKE '/data/%' OR TRIM(image_path) LIKE '/storage/%'
            THEN NULLIF(TRIM(image_path), '')
          ELSE NULL
        END,
        CASE
          WHEN TRIM(thumbnail_path) LIKE '/data/%' OR TRIM(thumbnail_path) LIKE '/storage/%'
            THEN NULLIF(TRIM(thumbnail_path), '')
          ELSE NULL
        END,
        NULLIF(TRIM((
          SELECT p.image_url
          FROM tbl_photos p
          WHERE (
            p.photo_id = tbl_scan_record.id OR
            (p.id = tbl_scan_record.id AND (p.photo_id IS NULL OR p.photo_id = tbl_scan_record.id))
          )
            AND p.image_url IS NOT NULL
            AND TRIM(p.image_url) != ''
          ORDER BY p.id DESC
          LIMIT 1
        )), '')
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

  Future<void> batchUpsertPhotos(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;

    final db = await database;
    await db.transaction((txn) async {
      final existing = await txn.query(
        'tbl_photos',
        columns: ['name', 'timestamp'],
      );
      final existingKeys = <String>{
        for (final row in existing)
          '${row['name'] as String}|${row['timestamp'] as String}',
      };

      for (final row in rows) {
        final name = (row['name'] as String?)?.trim() ?? '';
        final timestamp = (row['timestamp'] as String?)?.trim() ?? '';
        if (name.isEmpty || timestamp.isEmpty) continue;

        final key = '$name|$timestamp';
        if (existingKeys.contains(key)) continue;

        await txn.insert('tbl_photos', {
          'name': name,
          'data': (row['data'] as String?) ?? '',
          'timestamp': timestamp,
          if (row['path'] != null) 'path': row['path'],
          if (row['title'] != null) 'title': row['title'],
          if (row['description'] != null) 'description': row['description'],
          if (row['image_url'] != null) 'image_url': row['image_url'],
          if (row['checksum'] != null) 'checksum': row['checksum'],
          if (row['source'] != null) 'source': row['source'],
          if (row['updated_at'] != null) 'updated_at': row['updated_at'],
          if (row['disease'] != null) 'disease': row['disease'],
          if (row['confidence'] != null) 'confidence': row['confidence'],
          if (row['severity_value'] != null)
            'severity_value': row['severity_value'],
          if (row['photo_id'] != null) 'photo_id': row['photo_id'],
          if (row['scan_dir'] != null) 'scan_dir': row['scan_dir'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        existingKeys.add(key);
      }
    });
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

  Future<List<Map<String, dynamic>>> getPhotosByScanIds(
    List<int> scanIds,
  ) async {
    if (scanIds.isEmpty) return [];
    final db = await database;
    final placeholders = List.filled(scanIds.length, '?').join(',');
    final results = await db.query(
      'tbl_photos',
      where: 'photo_id IN ($placeholders)',
      whereArgs: scanIds,
      orderBy: 'id DESC',
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

  Future<Map<String, dynamic>?> getMyTreeById(int id) async {
    final db = await database;
    final results = await db.query(
      'tbl_my_trees',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> addImagesToMyTree(int treeId, List<String> imageIds) async {
    if (imageIds.isEmpty) return;

    final row = await getMyTreeById(treeId);
    if (row == null) return;

    final raw = row['images']?.toString() ?? '';
    final existing = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final merged = <String>{
      ...existing,
      ...imageIds.map((e) => e.trim()).where((e) => e.isNotEmpty),
    };

    await updateMyTree(treeId, images: merged.join(','));
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
    String location = '',
  }) async {
    final db = await database;
    return await db.insert('tbl_dataset_folders', {
      'name': name,
      'location': location,
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

  Future<void> addImagesToDatasetFolder(
    String folderName,
    List<String> imageIds,
  ) async {
    if (imageIds.isEmpty) return;

    final db = await database;
    final rows = await db.query(
      'tbl_dataset_folders',
      where: 'name = ?',
      whereArgs: [folderName],
      limit: 1,
    );

    final incoming = imageIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (incoming.isEmpty) return;

    if (rows.isEmpty) {
      await insertDatasetFolder(
        name: folderName,
        imageIds: incoming,
        dateCreated: DateTime.now().toIso8601String(),
      );
      return;
    }

    final existingFolder = DatasetFolder.fromMap(rows.first);
    final merged = <String>{...existingFolder.images, ...incoming};

    await db.update(
      'tbl_dataset_folders',
      {'images': merged.join(',')},
      where: 'name = ?',
      whereArgs: [folderName],
    );
  }

  Future<void> generateDatasetsFromTrees() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        TRIM(t.name) AS tree_name,
        TRIM(COALESCE(t.location, '')) AS tree_location,
        CAST(r.id AS TEXT) AS scan_id
      FROM tbl_scan_record r
      INNER JOIN tbl_tree t ON r.tree_id = t.id
      WHERE t.name IS NOT NULL AND TRIM(t.name) != ''
      ORDER BY tree_name COLLATE NOCASE ASC, r.id ASC
    ''');

    final grouped = <String, List<String>>{};
    final groupedLocations = <String, String>{};
    for (final row in rows) {
      final treeName = (row['tree_name']?.toString() ?? '').trim();
      final treeLocation = (row['tree_location']?.toString() ?? '').trim();
      final scanId = (row['scan_id']?.toString() ?? '').trim();
      if (treeName.isEmpty || scanId.isEmpty) continue;
      grouped.putIfAbsent(treeName, () => <String>[]).add(scanId);
      if (treeLocation.isNotEmpty) {
        groupedLocations.putIfAbsent(treeName, () => treeLocation);
      }
    }

    if (grouped.isEmpty) return;

    final nowIso = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      for (final entry in grouped.entries) {
        final treeName = entry.key;
        final incoming = entry.value
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (incoming.isEmpty) continue;

        final existingRows = await txn.query(
          'tbl_dataset_folders',
          columns: ['images', 'location'],
          where: 'name = ?',
          whereArgs: [treeName],
          limit: 1,
        );

        if (existingRows.isEmpty) {
          final uniqueIncoming = <String>{...incoming}.toList();
          await txn.insert('tbl_dataset_folders', {
            'name': treeName,
            'location': groupedLocations[treeName] ?? '',
            'images': uniqueIncoming.join(','),
            'date_created': nowIso,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          continue;
        }

        final existingRaw = existingRows.first['images']?.toString() ?? '';
        final existingLocation =
            existingRows.first['location']?.toString().trim() ?? '';
        final existingIds = existingRaw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        final merged = <String>{...existingIds, ...incoming};
        final incomingLocation = groupedLocations[treeName] ?? '';
        final locationToSave = existingLocation.isNotEmpty
            ? existingLocation
            : incomingLocation;

        await txn.update(
          'tbl_dataset_folders',
          {'images': merged.join(','), 'location': locationToSave},
          where: 'name = ?',
          whereArgs: [treeName],
        );
      }
    });
  }
}

class _SeverityBucketCounter {
  int healthy = 0;
  int early = 0;
  int advanced = 0;

  int get total => healthy + early + advanced;
}
