class Visit {
  int? id;
  int patientId;
  DateTime visitDate;
  String procedure;
  String investigations;
  String treatments;
  String advices;
  String? nextVisitDate;

  Visit({
    this.id,
    required this.patientId,
    required this.visitDate,
    required this.procedure,
    required this.investigations,
    required this.treatments,
    required this.advices,
    this.nextVisitDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'visitDate': visitDate.toIso8601String(),
      'procedure': procedure,
      'investigations': investigations,
      'treatments': treatments,
      'advices': advices,
      'nextVisitDate': nextVisitDate,
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map) {
    return Visit(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      patientId: map['patientId'] != null ? int.parse(map['patientId'].toString()) : 0,
      visitDate: map['visitDate'] != null ? DateTime.parse(map['visitDate'].toString()) : DateTime.now(),
      procedure: map['procedure']?.toString() ?? '',
      investigations: map['investigations']?.toString() ?? '',
      treatments: map['treatments']?.toString() ?? '',
      advices: map['advices']?.toString() ?? '',
      nextVisitDate: map['nextVisitDate']?.toString(),
    );
  }
}
