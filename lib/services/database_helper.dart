// تعديل الدوال التي تستخدم fromMap
// السطر 66 تقريباً
Future<List<Patient>> getPatients() async {
  final db = await database;
  final result = await db.query('patients');
  return result.map((map) => Patient.fromMap(map)).toList();
}

// السطر 74 تقريباً
Future<Patient?> getPatient(String id) async {
  final db = await database;
  final result = await db.query('patients', where: 'id = ?', whereArgs: [id]);
  if (result.isNotEmpty) {
    return Patient.fromMap(result.first);
  }
  return null;
}

// السطر 104 تقريباً
Future<List<Visit>> getVisits(String patientId) async {
  final db = await database;
  final result = await db.query('visits', where: 'patientId = ?', whereArgs: [patientId]);
  return result.map((map) => Visit.fromMap(map)).toList();
}
