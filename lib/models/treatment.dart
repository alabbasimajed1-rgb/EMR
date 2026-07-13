class Treatment {
  String medicineName;
  String dose;
  String duration;

  Treatment({
    required this.medicineName,
    required this.dose,
    required this.duration,
  });

  Map<String, dynamic> toMap() => {
        'medicineName': medicineName,
        'dose': dose,
        'duration': duration,
      };

  factory Treatment.fromMap(Map<String, dynamic> map) => Treatment(
        medicineName: map['medicineName'] ?? '',
        dose: map['dose'] ?? '',
        duration: map['duration'] ?? '',
      );
}
