import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/scan_model.dart'; 

// Helper class to hold the aggregated summary data
class ScanSummary {
  final int totalScans;
  final int healthyCount;
  final int moderateCount;
  final int severeCount;

  ScanSummary({
    required this.totalScans,
    required this.healthyCount,
    required this.moderateCount,
    required this.severeCount,
  });
}

class DatabaseService {
  // Singleton Setup
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

  // Table and column names
  final String _scanTableName = "scan_history";
  final String _colId = "id";
  final String _colDisease = "disease";
  final String _colSeverityValue = "severity_value"; 
  final String _colStatus = "status"; 
  final String _colDate = "date"; 

  DatabaseService._constructor();

  // Core Database Management
  Future<Database> get database async {
    if (_db != null) return _db!;
    // Private initialization method
    _db = await _initDatabase(); 
    return _db!;
  }

  // Initialization method 
  Future<Database> _initDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "mangofy.db");

    print('Database Path: $databasePath');
    
    // Increment version to force onCreate/onUpgrade, ensuring the new table is created
    final database = await openDatabase(
      databasePath,
      version: 3, 
      onCreate: (db, version) {
        // Create the new scan_history table
        return db.execute('''
        CREATE TABLE $_scanTableName (
          $_colId INTEGER PRIMARY KEY AUTOINCREMENT,
          $_colDisease TEXT NOT NULL,
          $_colSeverityValue REAL NOT NULL,
          $_colStatus TEXT NOT NULL,
          $_colDate TEXT NOT NULL
        )
        ''');
      },
    );
    return database;
  }
  
  /// Closes the database connection. Essential to prevent resource leaks.
  Future<void> closeDatabase() async {
    final db = _db;
    if (db != null && db.isOpen) {
      await db.close();
      _db = null; // Clear the instance reference
    }
  }

  /// Deletes the physical database file entirely (e.g., for full application reset).
  Future<void> deleteDbFile() async {
    await closeDatabase(); // Must close the connection before deleting the file
    
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "mangofy.db");
    
    await deleteDatabase(databasePath); 
    _db = null; 
  }


  // Inserts a new scan record into the database.
  Future<int> insertScan({
    required String disease,
    required double severityValue,
    required String status,
    required String date,
  }) async {
    final db = await database;
    return await db.insert(
      _scanTableName,
      {
        _colDisease: disease,
        _colSeverityValue: severityValue,
        _colStatus: status,
        _colDate: date,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Retrieves all scan records from the database, ordered by most recent first.
  Future<List<Map<String, dynamic>>> getAllScans() async {
    final db = await database;
    return await db.query(
      _scanTableName,
      orderBy: '$_colId DESC', 
    );
  }

  ///Updates an existing scan record. 
  Future<int> updateScan(ScanRecord record) async {
    final db = await database;
    // Uses the new toMap() method on the ScanRecord object
    final map = record.toMap(); 
    return await db.update(
      _scanTableName,
      map,
      where: '$_colId = ?',
      whereArgs: [record.id], 
    );
  }
  
  // Deletes a specific scan record by its ID.
  Future<int> deleteScan(int id) async {
    final db = await database;
    return await db.delete(
      _scanTableName,
      where: '$_colId = ?',
      whereArgs: [id],
    );
  }
  
  // Deletes all records from the scan history table.
  Future<int> deleteAllScans() async {
    final db = await database;
    return await db.delete(_scanTableName);
  }
  
  // Aggregation Method 

  // Calculates summary statistics for the home page.
  Future<ScanSummary> getScanSummary() async {
    final db = await database;
    // Get all records for simple in-memory aggregation
    final List<Map<String, dynamic>> maps = await db.query(_scanTableName);

    int totalScans = maps.length;
    int healthyCount = 0;
    int moderateCount = 0;
    int severeCount = 0;

    for (final map in maps) {
      // Use the ScanRecord model to get the calculated status
      final record = ScanRecord.fromMap(map); 
      switch (record.status) {
        case 'Healthy':
          healthyCount++;
          break;
        case 'Moderate':
          moderateCount++;
          break;
        case 'Severe':
          severeCount++;
          break;
      }
    }

    return ScanSummary(
      totalScans: totalScans,
      healthyCount: healthyCount,
      moderateCount: moderateCount,
      severeCount: severeCount,
    );
  }
}