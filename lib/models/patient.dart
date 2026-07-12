class Patient {
  final String? id;
  final String fullName;
  final int age;
  final String chiefComplaint;
  final String? medicalHistory;
  final String investigationAndImaging;
  final String differentialDiagnosis;
  final String finalDiagnosis;
  final String firstTreatmentPlan;
  final DateTime firstVisitDate;

  Patient({
    this.id,
    required this.fullName,
    required this.age,
    required this.chiefComplaint,
    this.medicalHistory,
    required this.investigationAndImaging,
    required this.differentialDiagnosis,
    required this.finalDiagnosis,
    required this.firstTreatmentPlan,
    required this.firstVisitDate,
  });

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id']?.toString(),
      fullName: map['fullName'] ?? '',
      age: map['age'] ?? 0,
      chiefComplaint: map['chiefComplaint'] ?? '',
      medicalHistory: map['medicalHistory'],
      investigationAndImaging: map['investigationAndImaging'] ?? '',
      differentialDiagnosis: map['differentialDiagnosis'] ?? '',
      finalDiagnosis: map['finalDiagnosis'] ?? '',
      firstTreatmentPlan: map['firstTreatmentPlan'] ?? '',
      firstVisitDate: DateTime.tryParse(map['firstVisitDate'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      'chiefComplaint': chiefComplaint,
      'medicalHistory': medicalHistory,
      'investigationAndImaging': investigationAndImaging,
      'differentialDiagnosis': differentialDiagnosis,
      'finalDiagnosis': finalDiagnosis,
      'firstTreatmentPlan': firstTreatmentPlan,
      'firstVisitDate': firstVisitDate.toIso8601String(),
    };
  }
}
