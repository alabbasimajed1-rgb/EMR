import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../services/database_helper.dart';
import 'new_visit_screen.dart';
import 'visits_details_screen.dart'; // تأكد أن الاسم يطابق الموجود في الصورة لديك

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  List<Visit> _visits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    final visits = await DatabaseHelper.instance.getVisitsForPatient(widget.patient.id!);
    if (mounted) {
      setState(() {
        _visits = visits;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Patient Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : Column(
              children: [
                _buildPatientInfoCard(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Clinical Visits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  ),
                ),
                Expanded(
                  child: _visits.isEmpty
                      ? Center(child: Text('No visits recorded yet.', style: TextStyle(color: Colors.grey.shade600)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _visits.length,
                          itemBuilder: (context, index) {
                            final visit = _visits[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.withOpacity(0.1),
                                  child: const Icon(Icons.monitor_heart, color: Colors.green),
                                ),
                                title: Text(
                                  'Visit Date: ${visit.visitDate.toLocal().toString().split(' ')[0]}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  visit.procedure?.isNotEmpty == true ? visit.procedure! : 'General Follow-up',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => VisitsDetailsScreen(visit: visit)),
                                  ).then((_) => _loadVisits());
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewVisitScreen(patientId: widget.patient.id!)),
          ).then((_) => _loadVisits());
        },
        backgroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Visit', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
            child: const Icon(Icons.person, size: 40, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.patient.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('Age: ${widget.patient.age} | Gender: ${widget.patient.gender}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                if (widget.patient.contact?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('Contact: ${widget.patient.contact}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
