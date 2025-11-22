import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/scan_summary_model.dart';
import '../model/scan_model.dart';
import '../model/my_tree_model.dart';
import '../model/dataset_folder_model.dart'; // Ensure this model exists

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  // Table names
  static const String scanTable = "scan_history";
  static const String treesTable = "my_trees";
  static const String datasetsTable = "dataset_folders";

  // Column names
  static const String colId = "id";
  static const String colDisease = "disease";
  static const String colSeverityValue = "severity_value";
  static const String colStatus = "status";
  static const String colDate = "date";

  static const String colTreeTitle = "title";
  static const String colTreeLocation = "location";
  static const String colTreeImages = "images";
  static const String colTreeCover = "cover_image";

  static const String colFolderName = "name";
  static const String colFolderImages = "images";
  static const String colDateCreated = "date_created";

  // Public getter
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDB("mangofy.db");
    return _database!;
  }

  Future<Database> _openDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6, // <--- INCREMENTED VERSION TO 6 FOR MIGRATION
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // Create Tables
  // This runs for brand new installs (version 6 is created)
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $scanTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colDisease TEXT NOT NULL,
        $colSeverityValue REAL NOT NULL,
        $colStatus TEXT NOT NULL,
        $colDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $treesTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colTreeTitle TEXT NOT NULL UNIQUE,
        $colTreeLocation TEXT,
        $colTreeImages TEXT,
        $colTreeCover TEXT
      )
    ''');

    // Dataset table creation for new installs
    await db.execute('''
      CREATE TABLE $datasetsTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colFolderName TEXT NOT NULL UNIQUE,
        $colFolderImages TEXT NOT NULL,
        $colDateCreated TEXT NOT NULL
      )
    ''');
  }

  // Upgrade / Migrations
  // This runs for existing users when version changes (e.g., from 5 to 6)
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migration for versions < 4 (creating my_trees table)
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $treesTable (
          $colId INTEGER PRIMARY KEY AUTOINCREMENT,
          $colTreeTitle TEXT NOT NULL UNIQUE,
          $colTreeLocation TEXT,
          $colTreeImages TEXT,
          $colTreeCover TEXT
        )
      ''');
    }

    // Migration for versions < 5 (potentially a fix for my_trees)
    // NOTE: This block is redundant, but kept for historical context.
    if (oldVersion < 5) {
      // The logic here is typically for changes in V5, but the existing code is incomplete.
    }

    // New Migration for versions < 6: Create the dataset_folders table
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $datasetsTable (
          $colId INTEGER PRIMARY KEY AUTOINCREMENT,
          $colFolderName TEXT NOT NULL UNIQUE,
          $colFolderImages TEXT NOT NULL,
          $colDateCreated TEXT NOT NULL
        )
      ''');
    }
  }

  // Scan Records
  Future<int> insertScan({
    required String disease,
    required double severityValue,
    required String status,
    required String date,
  }) async {
    final db = await instance.database;

    return await db.insert(scanTable, {
      colDisease: disease,
      colSeverityValue: severityValue,
      colStatus: status,
      colDate: date,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllScans() async {
    final db = await instance.database;
    return await db.query(scanTable, orderBy: "$colId DESC");
  }

  Future<int> updateScan(ScanRecord record) async {
    final db = await instance.database;

    return db.update(
      scanTable,
      record.toMap(),
      where: "$colId = ?",
      whereArgs: [record.id],
    );
  }

  Future<int> deleteScan(int id) async {
    final db = await instance.database;

    return db.delete(scanTable, where: "$colId = ?", whereArgs: [id]);
  }

  Future<int> deleteAllScans() async {
    final db = await instance.database;
    return await db.delete(scanTable);
  }

  // Scan Summary Aggregation
  Future<ScanSummary> getScanSummary() async {
    final db = await instance.database;
    final maps = await db.query(scanTable);

    int total = maps.length;
    int healthy = 0, moderate = 0, severe = 0;

    for (final map in maps) {
      final r = ScanRecord.fromMap(map);

      switch (r.status) {
        case "Healthy":
          healthy++;
          break;
        case "Moderate":
          moderate++;
          break;
        case "Severe":
          severe++;
          break;
      }
    }

    return ScanSummary(
      totalScans: total,
      healthyCount: healthy,
      moderateCount: moderate,
      severeCount: severe,
    );
  }

  // My Trees
  Future<int> insertMyTree({
    required String title,
    String location = '',
    required List<String> imageIds,
    String coverImage = "images/leaf.png",
  }) async {
    final db = await instance.database;

    final tree = MyTree(
      title: title,
      location: location,
      images: imageIds,
      coverImage: coverImage,
    );

    return await db.insert(
      treesTable,
      tree.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MyTree>> getAllMyTrees() async {
    final db = await instance.database;
    final maps = await db.query(treesTable);
    return maps.map((m) => MyTree.fromMap(m)).toList();
  }

  Future<int> updateMyTreeTitle(String oldTitle, String newTitle) async {
    final db = await instance.database;
    return db.update(
      treesTable,
      {colTreeTitle: newTitle},
      where: "$colTreeTitle = ?",
      whereArgs: [oldTitle],
    );
  }

  // New method: Delete a tree by title
  Future<int> deleteMyTree(String title) async {
    final db = await instance.database;
    return db.delete(
      treesTable,
      where: "$colTreeTitle = ?",
      whereArgs: [title],
    );
  }

  // Dataset Folders
  Future<int> insertDatasetFolder({
    required String name,
    required List<String> imageIds,
    required String dateCreated,
  }) async {
    final db = await instance.database;

    final folder = DatasetFolder(
      name: name,
      images: imageIds,
      dateCreated: dateCreated,
    );

    return await db.insert(
      datasetsTable,
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DatasetFolder>> getAllDatasetFolders() async {
    final db = await instance.database;
    // Query the table in descending order of ID (most recent first)
    final maps = await db.query(datasetsTable, orderBy: "$colId DESC");
    return maps.map((m) => DatasetFolder.fromMap(m)).toList();
  }

  // DB Close / Reset
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "mangofy.db");
    await deleteDatabase(path);
    _database = null;
  }
}
