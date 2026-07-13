import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../services/database_helper.dart'; 
import 'add_edit_patient_screen.dart';
import 'new_visit_screen.dart';
import 'visits_details_screen.dart'; 

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  late Patient _patient;
  late Future<List<Visit>> _visitsFuture;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _loadVisits(); 
  }

  void _loadVisits() {
    _visitsFuture = DatabaseHelper.instance.getVisitsForPatient(_patient.id!);
  }

  void _editPatient() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPatientScreen(patient: _patient),
      ),
    );

    if (result == true) {
      _refreshPatient();
    }
  }

  void _refreshPatient() async {
    try {
      final patients = await DatabaseHelper.instance.getAllPatients();
      final updatedPatient = patients.firstWhere((p) => p.id == _patient.id);
      if (mounted) {
        setState(() {
          _patient = updatedPatient;
        });
      }
    } catch (e) {}
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 20, color: Colors.blue.shade800),
                ),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.blue.shade900)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B), height: 1.4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Patient Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.edit_note, size: 28), onPressed: _editPatient),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 3)),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Text(
                        _patient.fullName.isNotEmpty ? _patient.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_patient.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildBadge(Icons.cake_outlined, '${_patient.age} Yrs'),
                            const SizedBox(width: 12),
                            _buildBadge(_patient.gender == 'Male' ? Icons.male : Icons.female, _patient.gender),
                          ],
                        ),
                        if (_patient.phoneNumber.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Text(_patient.phoneNumber, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: 'Clinical Assessment',
                    icon: Icons.assignment_ind_outlined,
                    children: [
                      _buildDataField('Chief Complaint', _patient.chiefComplaint),
                      _buildDataField('Medical History', _patient.medicalHistory),
                    ],
                  ),

                  if (_patient.investigationAndImaging.isNotEmpty || _patient.differentialDiagnosis.isNotEmpty || _patient.finalDiagnosis.isNotEmpty)
                    _buildSectionCard(
                      title: 'Diagnostics & Investigations',
                      icon: Icons.biotech_outlined,
                      children: [
                        _buildDataField('Investigations & Imaging', _patient.investigationAndImaging),
                        _buildDataField('Differential Diagnosis', _patient.differentialDiagnosis),
                        _buildDataField('Final Diagnosis', _patient.finalDiagnosis),
                      ],
                    ),

                  if (_patient.firstTreatmentPlan.isNotEmpty)
                    _buildSectionCard(
                      title: 'Management Plan',
                      icon: Icons.medical_services_outlined,
                      children: [
                        _buildDataField('Initial Treatment', _patient.firstTreatmentPlan),
                      ],
                    ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Clinical Visits', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.blue.shade900)),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // تم حل مشكلة نوع البيانات هنا (String بدل int)
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => NewVisitScreen(patientId: _patient.id!.toString())));
                          setState(() => _loadVisits());
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Visit'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  FutureBuilder<List<Visit>>(
                    future: _visitsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
                      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          width: double.infinity, padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, width: 2)),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('No visits recorded yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }

                      final visits = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visits.length,
                        itemBuilder: (context, index) {
                          final visit = visits[index];
                          // تم إصلاح مشكلة الأقواس وزر InkWell هنا
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12), 
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VisitDetailsScreen(visit: visit))),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: const Color(0xFF0F766E).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                      child: const Icon(Icons.monitor_heart_outlined, color: Color(0xFF0F766E)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(visit.procedure, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_month, size: 14, color: Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              Text(visit.visitDate.toString().substring(0, 10), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
