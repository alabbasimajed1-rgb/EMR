import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/visit.dart';

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
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // جدول المرضى المحدث
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        contact TEXT,
        medicalHistory TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // جدول الزيارات المحدث
    await db.execute('''
      CREATE TABLE visits (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        visitDate TEXT NOT NULL,
        chiefComplaint TEXT,
        investigations TEXT,
        differentialDiagnosis TEXT,
        finalDiagnosis TEXT,
        treatmentPlan TEXT,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');
  }

  // ملاحظة: تذكر تحديث دوال insert و query في هذا الملف لتناسب الحقول الجديدة.
}
