import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

  final String _datasetTableName = "dataset";
  final String _datasetIdColumnName = "id";

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "mangofy_db.db");
    final database = await openDatabase(
      databasePath,
      onCreate: (db,version) {
        db.execute('''
        CREATE TABLE $_datasetTableName (
          $_datasetIdColumnName MEDIUMINT PRIMARY KEY
        )
        ''');
      }
    );
    return database;
  }
}
