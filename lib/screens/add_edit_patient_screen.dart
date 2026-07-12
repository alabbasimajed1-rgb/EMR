import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/database_helper.dart';

class AddPatientScreen extends StatefulWidget {
  final Patient? patient;
  const AddPatientScreen({super.key, this.patient});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _nameController = TextEditingController();
  // ... باقي الكونترولرز

  void _savePatient() async {
    final newPatient = Patient(
      id: widget.patient?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      age: 30, // اجعلها ديناميكية
      gender: 'Male',
      createdAt: widget.patient?.createdAt ?? DateTime.now().toIso8601String(),
    );
    await DatabaseHelper.instance.createPatient(newPatient);
    if (mounted) Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) { /* ... */ return Container(); }
}
