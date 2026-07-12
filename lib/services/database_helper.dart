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
    // يمكنك زيادة رقم الـ version إذا احتجت لتغيير هيكلية الجدول مستقبلاً
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // إنشاء جدول المرضى
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        fullName TEXT,
        age INTEGER,
        gender TEXT,
        firstVisitDate TEXT,
        chiefComplaint TEXT,
        medicalHistory TEXT,
        investigationAndImaging TEXT,
        differentialDiagnosis TEXT,
        finalDiagnosis TEXT,
        firstTreatmentPlan TEXT
      )
    ''');

    // إنشاء جدول الزيارات
    await db.execute('''
      CREATE TABLE visits (
        id TEXT PRIMARY KEY,
        patientId TEXT,
        visitDate TEXT,
        procedure TEXT,
        investigations TEXT,
        treatments TEXT,
        advices TEXT,
        nextVisitDate TEXT
      )
    ''');
  }

  // ==========================================
  // دوال المرضى (Patients)
  // ==========================================

  // 1. جلب كل المرضى
  Future<List<Patient>> getPatients() async {
    final db = await database;
    final result = await db.query('patients');
    return result.map((map) => Patient.fromMap(map['id'] as String, map)).toList();
  }

  // 2. جلب مريض واحد بواسطة الـ ID (تستخدمها في دالة الـ Refresh)
  Future<Patient?> getPatientById(String id) async {
    final db = await database;
    final result = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Patient.fromMap(result.first['id'] as String, result.first);
    }
    return null;
  }

  // 3. إضافة مريض جديد
  Future<void> addPatient(Patient patient) async {
    final db = await database;
    await db.insert('patients', patient.toMap());
  }

  // 4. تحديث بيانات مريض
  Future<void> updatePatient(Patient patient) async {
    final db = await database;
    await db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  // ==========================================
  // دوال الزيارات (Visits)
  // ==========================================

  // 1. جلب كل الزيارات (لإحصائيات الشاشة الرئيسية)
  Future<List<Visit>> getAllVisits() async {
    final db = await database;
    final result = await db.query('visits');
    return result.map((map) => Visit.fromMap(map['id'] as String, map)).toList();
  }

  // 2. جلب زيارات مريض معين
  Future<List<Visit>> getVisitsForPatient(String patientId) async {
    final db = await database;
    final result = await db.query(
      'visits', 
      where: 'patientId = ?', 
      whereArgs: [patientId],
      orderBy: 'visitDate DESC'
    );
    return result.map((map) => Visit.fromMap(map['id'] as String, map)).toList();
  }

  // 3. إضافة زيارة جديدة
  Future<void> addVisit(Visit visit) async {
    final db = await database;
    await db.insert('visits', visit.toMap());
  }

  // 4. تحديث زيارة
  Future<void> updateVisit(Visit visit) async {
    final db = await database;
    await db.update(
      'visits',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }
}
