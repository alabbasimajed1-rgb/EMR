class Visit {
  String? id;
  String patientId;
  DateTime visitDate;
  String chiefComplaint;
  String investigations;
  String differentialDiagnosis;
  String finalDiagnosis;
  String treatmentPlan;

  Visit({
    this.id,
    required this.patientId,
    required this.visitDate,
    required this.chiefComplaint,
    required this.investigations,
    required this.differentialDiagnosis,
    required this.finalDiagnosis,
    required this.treatmentPlan,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'visitDate': visitDate.toIso8601String(),
      'chiefComplaint': chiefComplaint,
      'investigations': investigations,
      'differentialDiagnosis': differentialDiagnosis,
      'finalDiagnosis': finalDiagnosis,
      'treatmentPlan': treatmentPlan,
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map) {
    return Visit(
      id: map['id'],
      patientId: map['patientId'],
      visitDate: DateTime.parse(map['visitDate']),
      chiefComplaint: map['chiefComplaint'] ?? '',
      investigations: map['investigations'] ?? '',
      differentialDiagnosis: map['differentialDiagnosis'] ?? '',
      finalDiagnosis: map['finalDiagnosis'] ?? '',
      treatmentPlan: map['treatmentPlan'] ?? '',
    );
  }
}
