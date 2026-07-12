class Visit {
  final String? id;
  final String patientId;
  final String procedure;
  final DateTime visitDate;

  Visit({
    this.id,
    required this.patientId,
    required this.procedure,
    required this.visitDate,
  });

  factory Visit.fromMap(Map<String, dynamic> map) {
    return Visit(
      id: map['id']?.toString(),
      patientId: map['patientId'] ?? '',
      procedure: map['procedure'] ?? '',
      visitDate: DateTime.tryParse(map['visitDate'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'procedure': procedure,
      'visitDate': visitDate.toIso8601String(),
    };
  }
}
