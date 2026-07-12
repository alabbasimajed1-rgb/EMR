import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/database_helper.dart';
import 'patient_details_screen.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  List<Patient> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final dbHelper = DatabaseHelper.instance;
    final patients = await dbHelper.getAllPatients();
    
    if (mounted) {
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Patients', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : _patients.isEmpty
              ? Center(
                  child: Text('No patients found.',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _patients.length,
                  itemBuilder: (context, index) {
                    final patient = _patients[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                          child: const Icon(Icons.person, color: Color(0xFF1E3A8A)),
                        ),
                        title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Age: ${patient.age} | ${patient.gender}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientDetailsScreen(patient: patient),
                            ),
                          ).then((_) => _loadPatients()); // تحديث القائمة عند العودة
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
