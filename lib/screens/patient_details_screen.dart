import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../services/database_helper.dart';
import 'add_edit_patient_screen.dart';
import 'new_visit_screen.dart';
import 'visit_details_screen.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;
  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  late Patient _patient;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  void _editPatient() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddEditPatientScreen(patient: _patient)),
    );
    if (result == true) {
      _refreshPatient();
    }
  }

  // تحديث البيانات من قاعدة البيانات المحلية
  void _refreshPatient() async {
    final updatedPatient = await DatabaseHelper.instance.getPatientById(_patient.id!);
    if (updatedPatient != null && mounted) {
      setState(() => _patient = updatedPatient);
    }
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: Colors.blue.shade800)), const SizedBox(width: 12), Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.blue.shade900))]),
            const SizedBox(height: 16), const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)), const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDataField(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B), height: 1.4)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Patient Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), centerTitle: true, backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, elevation: 0, actions: [IconButton(icon: const Icon(Icons.edit_note, size: 28), onPressed: _editPatient)]),
      body: SingleChildScrollView(
        child: Column(children: [
          // الرأس
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            decoration: const BoxDecoration(color: Color(0xFF1E3A8A), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
            child: Row(children: [
              CircleAvatar(radius: 36, backgroundColor: Colors.white, child: Text(_patient.fullName[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_patient.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 12), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text('${_patient.age} Yrs', style: const TextStyle(color: Colors.white)))])])),
            ]),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _buildSectionCard(title: 'Clinical Assessment', icon: Icons.assignment_ind_outlined, children: [_buildDataField('Chief Complaint', _patient.chiefComplaint), _buildDataField('Medical History', _patient.medicalHistory)]),
              _buildSectionCard(title: 'Diagnostics', icon: Icons.biotech_outlined, children: [_buildDataField('Investigations', _patient.investigationAndImaging), _buildDataField('Differential Diagnosis', _patient.differentialDiagnosis), _buildDataField('Final Diagnosis', _patient.finalDiagnosis)]),
              _buildSectionCard(title: 'Management Plan', icon: Icons.medical_services_outlined, children: [_buildDataField('Initial Treatment', _patient.firstTreatmentPlan)]),
              
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Clinical Visits', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.blue.shade900)),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewVisitScreen(patientId: _patient.id!))).then((_) => setState(() {})),
                  icon: const Icon(Icons.add, size: 18), label: const Text('Add Visit'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                ),
              ]),
              const SizedBox(height: 16),
              
              // عرض الزيارات باستخدام FutureBuilder
              FutureBuilder<List<Visit>>(
                future: DatabaseHelper.instance.getVisitsForPatient(_patient.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('No visits yet');
                  
                  return ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final visit = snapshot.data![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(visit.procedure, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(visit.visitDate.toString().substring(0, 10)),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitDetailsScreen(visit: visit))),
                        ),
                      );
                    },
                  );
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
