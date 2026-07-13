import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/visit.dart';

class DatabaseHelper {
  static const _databaseName = "emr_database.db";
  static const _databaseVersion = 2; 

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
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        phoneNumber TEXT DEFAULT '',
        chiefComplaint TEXT,
        medicalHistory TEXT,
        investigationAndImaging TEXT,
        differentialDiagnosis TEXT,
        finalDiagnosis TEXT,
        firstTreatmentPlan TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER NOT NULL,
        visitDate TEXT NOT NULL,
        procedure TEXT NOT NULL,
        investigations TEXT NOT NULL,
        treatments TEXT NOT NULL,
        advices TEXT NOT NULL,
        nextVisitDate TEXT,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE patients ADD COLUMN phoneNumber TEXT DEFAULT ''");
    }
  }

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
    // تم إصلاح الخطأ في هذا السطر
    return List.generate(maps.length, (i) => Visit.fromMap(maps[i]['id'].toString(), maps[i]));
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
