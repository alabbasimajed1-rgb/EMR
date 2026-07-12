import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../services/database_helper.dart';

class NewVisitScreen extends StatefulWidget {
  final String patientId;
  const NewVisitScreen({super.key, required this.patientId});

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen> {
  final _chiefComplaintController = TextEditingController();
  final _investigationsController = TextEditingController();
  final _diffDiagnosisController = TextEditingController();
  final _finalDiagnosisController = TextEditingController();
  final _treatmentPlanController = TextEditingController();

  void _saveVisit() async {
    final newVisit = Visit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: widget.patientId,
      visitDate: DateTime.now(),
      chiefComplaint: _chiefComplaintController.text,
      investigations: _investigationsController.text,
      differentialDiagnosis: _diffDiagnosisController.text,
      finalDiagnosis: _finalDiagnosisController.text,
      treatmentPlan: _treatmentPlanController.text,
    );
    await DatabaseHelper.instance.createVisit(newVisit);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Visit")),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _chiefComplaintController, decoration: const InputDecoration(labelText: 'Chief Complaint')),
        TextField(controller: _investigationsController, decoration: const InputDecoration(labelText: 'Investigations')),
        TextField(controller: _diffDiagnosisController, decoration: const InputDecoration(labelText: 'Differential Diagnosis')),
        TextField(controller: _finalDiagnosisController, decoration: const InputDecoration(labelText: 'Final Diagnosis')),
        TextField(controller: _treatmentPlanController, decoration: const InputDecoration(labelText: 'Treatment Plan')),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _saveVisit, child: const Text("Save Visit"))
      ]),
    );
  }
}
