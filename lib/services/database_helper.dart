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

  // ==========================================
  // دوال إدارة المرضى (Patients)
  // ==========================================

  // إضافة مريض جديد
  Future<Patient> createPatient(Patient patient) async {
    final db = await instance.database;
    patient.id = patient.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('patients', patient.toMap());
    return patient;
  }

  // قراءة كل المرضى
  Future<List<Patient>> getAllPatients() async {
    final db = await instance.database;
    final result = await db.query('patients', orderBy: 'createdAt DESC');
    return result.map((json) => Patient.fromMap(json)).toList();
  }

  // تحديث بيانات المريض
  Future<int> updatePatient(Patient patient) async {
    final db = await instance.database;
    return await db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  // ==========================================
  // دوال إدارة الزيارات (Visits)
  // ==========================================

  // إضافة زيارة جديدة
  Future<Visit> createVisit(Visit visit) async {
    final db = await instance.database;
    visit.id = visit.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('visits', visit.toMap());
    return visit;
  }

  // قراءة سجل الزيارات لمريض معين
  Future<List<Visit>> getVisitsForPatient(String patientId) async {
    final db = await instance.database;
    final result = await db.query(
      'visits',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'visitDate DESC',
    );
    return result.map((json) => Visit.fromMap(json)).toList();
  }

  // تحديث بيانات زيارة موجودة
  Future<int> updateVisit(Visit visit) async {
    final db = await instance.database;
    return await db.update(
      'visits',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  // ==========================================
  // دوال إضافية للنظام
  // ==========================================

  // إغلاق قاعدة البيانات
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
