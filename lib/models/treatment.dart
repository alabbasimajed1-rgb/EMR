class Treatment {
  String? id;
  String visitId; // ربط الدواء بزيارة محددة (Foreign Key)
  String medicationName; // اسم الدواء
  String dosage; // الجرعة (مثال: 500mg, 5ml)
  String route; // طريقة الإعطاء (مثال: IV, IM, Oral)
  String frequency; // التكرار (مثال: Twice a day, q8h)
  String duration; // مدة الاستخدام (مثال: 5 Days)

  Treatment({
    this.id,
    required this.visitId,
    required this.medicationName,
    required this.dosage,
    required this.route,
    required this.frequency,
    required this.duration,
  });

  // تحويل كائن العلاج إلى خريطة بيانات للحفظ في SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visitId': visitId,
      'medicationName': medicationName,
      'dosage': dosage,
      'route': route,
      'frequency': frequency,
      'duration': duration,
    };
  }

  // استرجاع بيانات العلاج من SQLite وتحويلها إلى كائن
  factory Treatment.fromMap(Map<String, dynamic> map) {
    return Treatment(
      id: map['id'],
      visitId: map['visitId'],
      medicationName: map['medicationName'],
      dosage: map['dosage'],
      route: map['route'],
      frequency: map['frequency'],
      duration: map['duration'],
    );
  }
}
