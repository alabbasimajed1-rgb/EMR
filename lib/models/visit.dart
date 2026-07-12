class Visit {
  String? id;
  String patientId;
  DateTime visitDate;
  String? procedure;
  String? investigations;
  String? treatments;
  String? advices;
  DateTime? nextVisitDate;

  Visit({
    this.id,
    required this.patientId,
    required this.visitDate,
    this.procedure,
    this.investigations,
    this.treatments,
    this.advices,
    this.nextVisitDate,
  });

  // تحويل الزيارة للتخزين في الهاتف
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'visitDate': visitDate.toIso8601String(),
      'procedure': procedure,
      'investigations': investigations,
      'treatments': treatments,
      'advices': advices,
      'nextVisitDate': nextVisitDate?.toIso8601String(),
    };
  }

  // قراءة الزيارة من الهاتف
  factory Visit.fromMap(Map<String, dynamic> map) {
    return Visit(
      id: map['id'],
      patientId: map['patientId'],
      visitDate: DateTime.parse(map['visitDate']),
      procedure: map['procedure'],
      investigations: map['investigations'],
      treatments: map['treatments'],
      advices: map['advices'],
      nextVisitDate: map['nextVisitDate'] != null 
          ? DateTime.parse(map['nextVisitDate']) 
          : null,
    );
  }
}
