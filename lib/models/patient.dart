class Patient {
  final String? id;
  final String fullName;
  final int age;
  final String gender; // النوع (Male/Female)
  final String chiefComplaint; // الشكوى الرئيسية الأساسية (الحقل الجديد)
  final String medicalHistory;
  final String investigationAndImaging; // الفحوصات ونتائج الأشعة
  final String differentialDiagnosis; // التشخيص المبدئي
  final String finalDiagnosis; // التشخيص النهائي
  final String firstTreatmentPlan; // العلاجات واستخدامها
  final DateTime firstVisitDate;

  Patient({
    this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.chiefComplaint, // تمت الإضافة هنا
    required this.medicalHistory,
    required this.investigationAndImaging,
    required this.differentialDiagnosis,
    required this.finalDiagnosis,
    required this.firstTreatmentPlan,
    required this.firstVisitDate,
  });

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'age': age,
        'gender': gender,
        'chiefComplaint': chiefComplaint, // تمت الإضافة للرفع إلى القاعدة
        'medicalHistory': medicalHistory,
        'investigationAndImaging': investigationAndImaging,
        'differentialDiagnosis': differentialDiagnosis,
        'finalDiagnosis': finalDiagnosis,
        'firstTreatmentPlan': firstTreatmentPlan,
        'firstVisitDate': firstVisitDate.toIso8601String(),
      };

  factory Patient.fromMap(String id, Map<String, dynamic> map) => Patient(
        id: id,
        fullName: map['fullName'] ?? '',
        age: map['age'] ?? 0,
        gender: map['gender'] ?? 'Unknown',
        chiefComplaint: map['chiefComplaint'] ?? '', // قراءة الشكوى أو تركها فارغة للمرضى القدامى
        medicalHistory: map['medicalHistory'] ?? '',
        investigationAndImaging: map['investigationAndImaging'] ?? '',
        differentialDiagnosis: map['differentialDiagnosis'] ?? '',
        finalDiagnosis: map['finalDiagnosis'] ?? '',
        firstTreatmentPlan: map['firstTreatmentPlan'] ?? '',
        firstVisitDate: map['firstVisitDate'] != null
            ? DateTime.parse(map['firstVisitDate'])
            : DateTime.now(),
      );
}
