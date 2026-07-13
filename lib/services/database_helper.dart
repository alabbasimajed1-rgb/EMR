import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart'; // تأكد من أن المسار يطابق موقع ملفاتك
import '../models/visit.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('emr_local_database.db');
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

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // 1. إنشاء جدول المرضى (يطابق كلاس Patient تماماً)
    await db.execute('''
    CREATE TABLE patients (
      id $idType,
      fullName $textType,
      age $integerType,
      gender $textType,
      chiefComplaint $textType,
      medicalHistory $textType,
      investigationAndImaging $textType,
      differentialDiagnosis $textType,
      finalDiagnosis $textType,
      firstTreatmentPlan $textType,
      firstVisitDate $textType
    )
    ''');

    // 2. إنشاء جدول الزيارات (يطابق كلاس Visit تماماً)
    await db.execute('''
    CREATE TABLE visits (
      id $idType,
      patientId $textType,
      visitDate $textType,
      procedure $textType,
      investigations $textType,
      treatments $textType,
      advices $textType,
      nextVisitDate TEXT,
      FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
    )
    ''');
  }

  // ==========================================
  //            عمليات المرضى (Patients)
  // ==========================================

  // إضافة مريض جديد
  Future<String> insertPatient(Patient patient) async {
    final db = await instance.database;
    // توليد ID فريد بناءً على الوقت (بديل لمعرفات Firebase)
    final id = patient.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final data = patient.toMap();
    data['id'] = id; 

    await db.insert('patients', data, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  // جلب كل المرضى (للعرض في الواجهة الرئيسية)
  Future<List<Patient>> getAllPatients() async {
    final db = await instance.database;
    final maps = await db.query('patients', orderBy: 'firstVisitDate DESC');

    return maps.map((map) {
      final id = map['id'] as String;
      return Patient.fromMap(id, map);
    }).toList();
  }

  // تحديث بيانات مريض
  Future<int> updatePatient(Patient patient) async {
    final db = await instance.database;
    return db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  // حذف مريض
  Future<int> deletePatient(String id) async {
    final db = await instance.database;
    return await db.delete(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  //            عمليات الزيارات (Visits)
  // ==========================================

  // إضافة زيارة جديدة
  Future<String> insertVisit(Visit visit) async {
    final db = await instance.database;
    final id = visit.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final data = visit.toMap();
    data['id'] = id;

    await db.insert('visits', data, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  // جلب زيارات مريض معين
  Future<List<Visit>> getVisitsForPatient(String patientId) async {
    final db = await instance.database;
    final maps = await db.query(
      'visits',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'visitDate DESC',
    );

    return maps.map((map) {
      final id = map['id'] as String;
      return Visit.fromMap(id, map);
    }).toList();
  }

  // تحديث زيارة
  Future<int> updateVisit(Visit visit) async {
    final db = await instance.database;
    return db.update(
      'visits',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  // حذف زيارة
  Future<int> deleteVisit(String id) async {
    final db = await instance.database;
    return await db.delete(
      'visits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
