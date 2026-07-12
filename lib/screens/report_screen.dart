import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int totalPatients = 0;
  int totalVisits = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    final dbHelper = DatabaseHelper.instance;
    final patients = await dbHelper.getAllPatients();
    
    int visits = 0;
    for (var patient in patients) {
      final patientVisits = await dbHelper.getVisitsForPatient(patient.id!);
      visits += patientVisits.length;
    }

    if (mounted) {
      setState(() {
        totalPatients = patients.length;
        totalVisits = visits;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Clinical Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCard('Total Registered Patients', totalPatients.toString(), Icons.people),
                  const SizedBox(height: 20),
                  _buildStatCard('Total Clinical Visits', totalVisits.toString(), Icons.monitor_heart),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
            child: Icon(icon, size: 30, color: const Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                const SizedBox(height: 5),
                Text(title, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
