import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/my_tree_model.dart';
import '../model/dataset_folder_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  // Table names
  static const String treesTable = "my_trees";
  static const String datasetsTable = "dataset_folders";
  static const String photosTable = "photos";

  // Column names
  static const String colId = "id";
  static const String colDisease = "disease";
  static const String colSeverityValue = "severity_value";

  static const String colTreeTitle = "title";
  static const String colTreeLocation = "location";
  static const String colTreeImages = "images";
  static const String colTreeCover = "cover_image";

  static const String colFolderName = "name";
  static const String colFolderImages = "images";
  static const String colDateCreated = "date_created";

  static const String colPhotoData = "data";
  static const String colPhotoName = "name";
  static const String colPhotoTimestamp = "timestamp";
  static const String colPath = "path";
  // Additional scan fields
  static const String colTitle = "title";
  static const String colDescription = "description";
  static const String colImageUrl = "image_url";
  static const String colChecksum = "checksum";
  static const String colSource = "source";
  static const String colUpdatedAt = "updated_at";
  static const String colConfidence = "confidence";
  static const String colPhotoId = "photo_id";
  static const String colScanDir = "scan_dir";

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
      version: 9, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // Create Tables
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $treesTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colTreeTitle TEXT NOT NULL UNIQUE,
        $colTreeLocation TEXT,
        $colTreeImages TEXT,
        $colTreeCover TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $datasetsTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colFolderName TEXT NOT NULL UNIQUE,
        $colFolderImages TEXT NOT NULL,
        $colDateCreated TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $photosTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colPhotoName TEXT NOT NULL,
        $colPhotoData TEXT NOT NULL,
        $colPhotoTimestamp TEXT NOT NULL,
        $colPath TEXT
      )
    ''');
  }

  // Upgrade / Migrations
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

    // Migration for versions < 6: Create the dataset_folders table
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

    // Migration for versions < 7: Create the photos table
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $photosTable (
          $colId INTEGER PRIMARY KEY AUTOINCREMENT,
          $colPhotoName TEXT NOT NULL,
          $colPhotoData TEXT NOT NULL,
          $colPhotoTimestamp TEXT NOT NULL
        )
      ''');
    }

    // Migration for versions < 8: Add path column to photos table
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE $photosTable ADD COLUMN path TEXT');
    }

    // Migration for versions < 9: Add scan fields to photos table
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE $photosTable ADD COLUMN $colTitle TEXT');
      await db.execute('ALTER TABLE $photosTable ADD COLUMN $colDescription TEXT');
      await db.execute('ALTER TABLE $photosTable ADD COLUMN $colImageUrl TEXT');
      await db.execute('ALTER TABLE $photosTable ADD COLUMN $colChecksum TEXT');
      await db.execute('ALTER TABLE $photosTable ADD COLUMN $colSource TEXT');
      await db.execute('ALTER TABLE $photosTable ADD COLUMN $colUpdatedAt TEXT');
      await db.execute('ALTER TABLE $photosTable ADD COLUMN $colConfidence REAL');
      await db.execute('ALTER TABLE $photosTable ADD COLUMN $colPhotoId INTEGER');
      await db.execute('ALTER TABLE $photosTable ADD COLUMN $colScanDir TEXT');
    }
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

  // Delete a tree 
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

  // Update a dataset folder's name
  Future<int> updateDatasetFolderName(String oldName, String newName) async {
    final db = await instance.database;
    return db.update(
      datasetsTable,
      {colFolderName: newName},
      where: "$colFolderName = ?",
      whereArgs: [oldName],
    );
  }

  // Delete a dataset folder by name
  Future<int> deleteDatasetFolder(String name) async {
    final db = await instance.database;
    return db.delete(
      datasetsTable,
      where: "$colFolderName = ?",
      whereArgs: [name],
    );
  }

  // Remove a single image ID from a dataset folder's list
  // If the folder becomes empty, it is deleted.
  Future<void> removeImageFromDatasetFolder(
    String folderName,
    String imageIdToRemove,
  ) async {
    final db = await instance.database;

    // Fetch the existing folder data
    final maps = await db.query(
      datasetsTable,
      where: "$colFolderName = ?",
      whereArgs: [folderName],
      limit: 1,
    );

    if (maps.isEmpty) {
      return; // Folder not found
    }

    final folder = DatasetFolder.fromMap(maps.first);

    // Modify the image list
    final updatedImages = folder.images
        .where((id) => id != imageIdToRemove)
        .toList();

    // If the folder is now empty, delete it entirely.
    if (updatedImages.isEmpty) {
      await deleteDatasetFolder(folderName);
      return;
    }

    // Update the folder in the database with the new image list.
    // Create the updated folder object (ID will be null if not explicitly passed)
    final updatedFolder = DatasetFolder(
      name: folder.name,
      images: updatedImages,
      dateCreated: folder.dateCreated,
    );
    
    // Convert to map
    final updateMap = updatedFolder.toMap();
    
    // Remove the ID column from the map to prevent Sqflite from trying 
    // to update the primary key to NULL, which causes the datatype mismatch.
    updateMap.remove(colId);

    // DatasetFolder.toMap() converts List<String> images to a comma-separated String
    await db.update(
      datasetsTable,
      updateMap, // Pass the map without the ID
      where: "$colFolderName = ?",
      whereArgs: [folderName],
    );
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
    final db = await instance.database;

    return await db.insert(photosTable, {
      colPhotoName: name,
      colPhotoData: data ?? '', // Always provide a value for NOT NULL column
      colPhotoTimestamp: timestamp,
      if (path != null) colPath: path,
      if (title != null) colTitle: title,
      if (description != null) colDescription: description,
      if (imageUrl != null) colImageUrl: imageUrl,
      if (checksum != null) colChecksum: checksum,
      if (source != null) colSource: source,
      if (updatedAt != null) colUpdatedAt: updatedAt,
      if (disease != null) colDisease: disease,
      if (confidence != null) colConfidence: confidence,
      if (severityValue != null) colSeverityValue: severityValue,
      if (photoId != null) colPhotoId: photoId,
      if (scanDir != null) colScanDir: scanDir,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllPhotos() async {
    final db = await instance.database;
    return await db.query(photosTable, orderBy: "$colId DESC");
  }

  Future<int> deletePhoto(int id) async {
    final db = await instance.database;
    return db.delete(photosTable, where: "$colId = ?", whereArgs: [id]);
  }

  Future<bool> photoExists(String name, String timestamp) async {
    final db = await instance.database;
    final rows = await db.query(
      photosTable,
      where: "$colPhotoName = ? AND $colPhotoTimestamp = ?",
      whereArgs: [name, timestamp],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int?> getPhotoIdByNameTimestamp(String name, String timestamp) async {
    final db = await instance.database;
    final rows = await db.query(
      photosTable,
      columns: [colId],
      where: "$colPhotoName = ? AND $colPhotoTimestamp = ?",
      whereArgs: [name, timestamp],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first[colId] as int?;
  }

  Future<Map<String, dynamic>?> getPhotoById(int id) async {
    final db = await instance.database;
    final rows = await db.query(
      photosTable,
      where: "$colId = ?",
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> getPhotosByIds(List<int> ids) async {
    if (ids.isEmpty) return <Map<String, dynamic>>[];
    final db = await instance.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return db.query(
      photosTable,
      where: "$colId IN ($placeholders)",
      whereArgs: ids,
    );
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