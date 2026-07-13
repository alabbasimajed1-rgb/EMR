class Patient {
  int? id;
  String fullName;
  int age;
  String gender;
  String phoneNumber; // الحقل الجديد
  String chiefComplaint;
  String medicalHistory;
  String investigationAndImaging;
  String differentialDiagnosis;
  String finalDiagnosis;
  String firstTreatmentPlan;
  DateTime createdAt;

  Patient({
    this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    this.phoneNumber = '', // الحقل الجديد
    this.chiefComplaint = '',
    this.medicalHistory = '',
    this.investigationAndImaging = '',
    this.differentialDiagnosis = '',
    this.finalDiagnosis = '',
    this.firstTreatmentPlan = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'phoneNumber': phoneNumber, // الحقل الجديد
      'chiefComplaint': chiefComplaint,
      'medicalHistory': medicalHistory,
      'investigationAndImaging': investigationAndImaging,
      'differentialDiagnosis': differentialDiagnosis,
      'finalDiagnosis': finalDiagnosis,
      'firstTreatmentPlan': firstTreatmentPlan,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      fullName: map['fullName'],
      age: map['age'],
      gender: map['gender'],
      phoneNumber: map['phoneNumber'] ?? '', // الحقل الجديد
      chiefComplaint: map['chiefComplaint'] ?? '',
      medicalHistory: map['medicalHistory'] ?? '',
      investigationAndImaging: map['investigationAndImaging'] ?? '',
      differentialDiagnosis: map['differentialDiagnosis'] ?? '',
      finalDiagnosis: map['finalDiagnosis'] ?? '',
      firstTreatmentPlan: map['firstTreatmentPlan'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
