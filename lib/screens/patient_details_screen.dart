import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../services/database_helper.dart';

class PatientDetailsScreen extends StatelessWidget {
  final Patient patient;
  const PatientDetailsScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(patient.name)),
      body: FutureBuilder<List<Visit>>(
        future: DatabaseHelper.instance.getVisitsForPatient(patient.id!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final visit = snapshot.data![index];
              return ListTile(
                title: Text(visit.finalDiagnosis.isNotEmpty ? visit.finalDiagnosis : 'General Follow-up'),
                subtitle: Text(visit.visitDate.toString()),
              );
            },
          );
        },
      ),
    );
  }
}
