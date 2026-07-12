class Patient {
  String? id;
  String name;
  int age;
  String gender;
  String? contact;
  String? medicalHistory; // يشمل الأمراض المزمنة
  String createdAt;

  Patient({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.contact,
    this.medicalHistory,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'contact': contact,
      'medicalHistory': medicalHistory,
      'createdAt': createdAt,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      contact: map['contact'],
      medicalHistory: map['medicalHistory'],
      createdAt: map['createdAt'],
    );
  }
}
