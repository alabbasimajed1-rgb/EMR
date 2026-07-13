class Visit {
  final String? id;
  final String patientId;
  final DateTime visitDate;
  final String procedure;
  final String investigations; // فحوصات وأشعة الزيارة الجديدة
  final String treatments; // علاجات الزيارة
  final String advices; // النصائح (مثل إيقاف علاج معين)
  final DateTime? nextVisitDate; // موعد الزيارة القادمة (اختياري)

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

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'visitDate': visitDate.toIso8601String(),
        'procedure': procedure,
        'investigations': investigations,
        'treatments': treatments,
        'advices': advices,
        'nextVisitDate': nextVisitDate?.toIso8601String(), // قد يكون فارغاً
      };

  factory Visit.fromMap(String id, Map<String, dynamic> map) => Visit(
        id: id,
        patientId: map['patientId'] ?? '',
        visitDate: map['visitDate'] != null
            ? DateTime.parse(map['visitDate'])
            : DateTime.now(),
        procedure: map['procedure'] ?? '',
        investigations: map['investigations'] ?? '',
        treatments: map['treatments'] ?? '',
        advices: map['advices'] ?? '',
        nextVisitDate: map['nextVisitDate'] != null
            ? DateTime.parse(map['nextVisitDate'])
            : null,
      );
}
