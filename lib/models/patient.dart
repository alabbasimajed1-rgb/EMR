class Patient {
  String? id;
  String name;
  int age;
  String gender;
  String? contact;
  DateTime createdAt;

  Patient({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.contact,
    required this.createdAt,
  });

  // تحويل البيانات من التطبيق إلى قاعدة البيانات المحلية
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'contact': contact,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // استرجاع البيانات من قاعدة البيانات المحلية إلى التطبيق
  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      contact: map['contact'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
