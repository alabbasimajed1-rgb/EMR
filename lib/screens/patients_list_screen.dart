import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/database_helper.dart'; // استدعاء قاعدة البيانات المحلية
import 'add_edit_patient_screen.dart';
import 'patient_details_screen.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  List<Patient> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients(); // جلب المرضى عند فتح الشاشة
  }

  // دالة لجلب البيانات من الهاتف
  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final patientsData = await DatabaseHelper.instance.getAllPatients();
      setState(() {
        _patients = patientsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patients: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تصفية المرضى بناءً على نص البحث
    List<Patient> filteredPatients = _patients;
    if (_searchQuery.isNotEmpty) {
      filteredPatients = _patients.where((patient) {
        return patient.fullName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50, 
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4), 
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patient by name...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _patients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_shared_outlined, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No patients recorded yet.',
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : filteredPatients.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                const Text('No patients match your search', style: TextStyle(fontSize: 16, color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80, top: 8), 
                            itemCount: filteredPatients.length,
                            itemBuilder: (context, index) {
                              final patient = filteredPatients[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.blue.shade50,
                                    child: Text(
                                      patient.fullName.isNotEmpty
                                          ? patient.fullName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    patient.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Age: ${patient.age} | First Visit: ${patient.firstVisitDate.toString().substring(0, 10)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue.shade300),
                                  onTap: () async {
                                    // انتظار العودة من تفاصيل المريض لتحديث القائمة إذا تم تعديله
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PatientDetailsScreen(patient: patient),
                                      ),
                                    );
                                    _loadPatients(); 
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () async {
          // انتظار إضافة المريض الجديد، ثم تحديث القائمة
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditPatientScreen(),
            ),
          );
          
          if (result == true) {
            _loadPatients();
          }
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text("New Patient", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
