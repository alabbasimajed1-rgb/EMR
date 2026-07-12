import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/database_helper.dart'; // استخدمنا DatabaseHelper بدلاً من Firestore
import 'add_edit_patient_screen.dart';
import 'patient_details_screen.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  // تعريف الـ Future الذي سيحمل بيانات المرضى
  Future<List<Patient>>? _patientsFuture;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshPatients();
  }

  // دالة لجلب البيانات وتحديث الشاشة
  void _refreshPatients() {
    setState(() {
      _patientsFuture = DatabaseHelper.instance.getPatients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // شريط البحث (نفس التصميم)
          Container(
            margin: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patient by name...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          
          // قائمة المرضى (استخدام FutureBuilder)
          Expanded(
            child: FutureBuilder<List<Patient>>(
              future: _patientsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_shared_outlined, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No patients recorded yet.', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }

                // الفلترة محلياً
                List<Patient> patients = snapshot.data!.where((p) => 
                  p.fullName.toLowerCase().contains(_searchQuery)
                ).toList();

                if (patients.isEmpty) {
                  return Center(child: Text('No matching results', style: TextStyle(color: Colors.grey.shade600)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 8),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Text(patient.fullName[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                        ),
                        title: Text(patient.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Age: ${patient.age} | ${patient.firstVisitDate.toString().substring(0, 10)}'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue.shade300),
                        onTap: () async {
                          // عند العودة، نحدث القائمة في حال تم تعديل بيانات المريض
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetailsScreen(patient: patient)));
                          _refreshPatients();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        onPressed: () async {
          // التحديث بعد العودة من إضافة مريض
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditPatientScreen()));
          _refreshPatients();
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text("New Patient", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
