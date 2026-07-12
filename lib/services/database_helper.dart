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

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        age INTEGER NOT NULL,
        chiefComplaint TEXT NOT NULL,
        medicalHistory TEXT,
        investigationAndImaging TEXT NOT NULL,
        differentialDiagnosis TEXT NOT NULL,
        finalDiagnosis TEXT NOT NULL,
        firstTreatmentPlan TEXT NOT NULL,
        firstVisitDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE visits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId TEXT NOT NULL,
        procedure TEXT NOT NULL,
        visitDate TEXT NOT NULL,
        FOREIGN KEY (patientId) REFERENCES patients(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertPatient(Patient patient) async {
    final db = await database;
    return await db.insert('patients', patient.toMap());
  }

  Future<List<Patient>> getPatients() async {
    final db = await database;
    final result = await db.query('patients');
    return result.map((map) => Patient.fromMap(map)).toList();
  }

  Future<Patient?> getPatient(int id) async {
    final db = await database;
    final result = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Patient.fromMap(result.first);
    }
    return null;
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await database;
    return await db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<int> deletePatient(int id) async {
    final db = await database;
    return await db.delete(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertVisit(Visit visit) async {
    final db = await database;
    return await db.insert('visits', visit.toMap());
  }

  Future<List<Visit>> getVisits(int patientId) async {
    final db = await database;
    final result = await db.query(
      'visits',
      where: 'patientId = ?',
      whereArgs: [patientId],
    );
    return result.map((map) => Visit.fromMap(map)).toList();
  }

  Future<int> updateVisit(Visit visit) async {
    final db = await database;
    return await db.update(
      'visits',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<int> deleteVisit(int id) async {
    final db = await database;
    return await db.delete(
      'visits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
