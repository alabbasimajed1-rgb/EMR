import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/visit.dart';

class DatabaseHelper {
  static const _databaseName = "emr_database.db";
  static const _databaseVersion = 4; // تم رفع الإصدار لـ 4

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL, age INTEGER NOT NULL, gender TEXT NOT NULL,
        phoneNumber TEXT DEFAULT '', chiefComplaint TEXT, medicalHistory TEXT,
        investigationAndImaging TEXT, differentialDiagnosis TEXT, finalDiagnosis TEXT,
        firstTreatmentPlan TEXT, createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT, patientId INTEGER NOT NULL,
        visitDate TEXT NOT NULL, procedure TEXT NOT NULL, investigations TEXT NOT NULL,
        treatments TEXT NOT NULL, advices TEXT NOT NULL, nextVisitDate TEXT,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE visit_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visitId INTEGER NOT NULL,
        imagePath TEXT NOT NULL,
        FOREIGN KEY (visitId) REFERENCES visits (id) ON DELETE CASCADE
      )
    ''');

    // الجدول الجديد لصور المريض الأساسية
    await db.execute('''
      CREATE TABLE patient_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER NOT NULL,
        imagePath TEXT NOT NULL,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE patients ADD COLUMN phoneNumber TEXT DEFAULT ''");
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE visit_images (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          visitId INTEGER NOT NULL,
          imagePath TEXT NOT NULL,
          FOREIGN KEY (visitId) REFERENCES visits (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE patient_images (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          patientId INTEGER NOT NULL,
          imagePath TEXT NOT NULL,
          FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // --- دوال الصور ---
  Future<int> insertImage(int visitId, String path) async {
    Database db = await instance.database;
    return await db.insert('visit_images', {'visitId': visitId, 'imagePath': path});
  }

  Future<List<String>> getImagesForVisit(int visitId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('visit_images', where: 'visitId = ?', whereArgs: [visitId]);
    return maps.map((m) => m['imagePath'] as String).toList();
  }

  // دوال صور المريض
  Future<int> insertPatientImage(int patientId, String path) async {
    Database db = await instance.database;
    return await db.insert('patient_images', {'patientId': patientId, 'imagePath': path});
  }

  Future<List<String>> getImagesForPatient(int patientId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('patient_images', where: 'patientId = ?', whereArgs: [patientId]);
    return maps.map((m) => m['imagePath'] as String).toList();
  }

  // --- دوال المرضى والزيارات ---
  Future<int> insertPatient(Patient patient) async {
    Database db = await instance.database;
    return await db.insert('patients', patient.toMap());
  }

  Future<List<Patient>> getAllPatients() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('patients', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
  }

  Future<int> updatePatient(Patient patient) async {
    Database db = await instance.database;
    return await db.update('patients', patient.toMap(), where: 'id = ?', whereArgs: [patient.id]);
  }

  Future<int> deletePatient(int id) async {
    Database db = await instance.database;
    await db.delete('patient_images', where: 'patientId = ?', whereArgs: [id]);
    await db.delete('visits', where: 'patientId = ?', whereArgs: [id]); 
    return await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertVisit(Visit visit) async {
    Database db = await instance.database;
    return await db.insert('visits', visit.toMap());
  }

  Future<List<Visit>> getVisitsForPatient(int patientId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('visits', where: 'patientId = ?', whereArgs: [patientId], orderBy: 'visitDate DESC');
    return List.generate(maps.length, (i) => Visit.fromMap(maps[i]));
  }

  Future<int> updateVisit(Visit visit) async {
    Database db = await instance.database;
    return await db.update('visits', visit.toMap(), where: 'id = ?', whereArgs: [visit.id]);
  }

  Future<int> deleteVisit(int id) async {
    Database db = await instance.database;
    return await db.delete('visits', where: 'id = ?', whereArgs: [id]);
  }
}
