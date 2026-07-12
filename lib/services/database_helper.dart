import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('emr_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // فتح قاعدة البيانات وإنشاؤها إذا لم تكن موجودة
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';

    // 1. إنشاء جدول المرضى
    await db.execute('''
      CREATE TABLE patients (
        id $idType,
        name $textType,
        age $integerType,
        gender $textType,
        contact $textNullable,
        createdAt $textType
      )
    ''');

    // 2. إنشاء جدول الزيارات
    await db.execute('''
      CREATE TABLE visits (
        id $idType,
        patientId $textType,
        visitDate $textType,
        procedure $textNullable,
        investigations $textNullable,
        treatments $textNullable,
        advices $textNullable,
        nextVisitDate $textNullable,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');
  }

  // الدالة الخاصة بإغلاق قاعدة البيانات
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
