import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../services/database_helper.dart';
import 'add_edit_patient_screen.dart';
import 'reports_screen.dart';
import 'login_screen.dart'; // شاشة الدخول بالـ PIN
import 'patients_list_screen.dart'; 
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  // دالة الخروج (تعيد المستخدم لشاشة الدخول)
  Future<void> _logout() async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap, 
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
              const SizedBox(height: 16),
              Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isPrimary ? Colors.white : const Color(0xFF1E3A8A)),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isPrimary ? Colors.white : const Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = "${now.day} ${_getMonthName(now.month)} ${now.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 80),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(dateString, style: TextStyle(color: Colors.blue.shade200, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            const Text('Dr. Majid Abbas', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                          ]),
                          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // --- البطاقات الإحصائية باستخدام FutureBuilder ---
                Positioned(
                  top: 170, left: 24, right: 24,
                  child: Row(
                    children: [
                      FutureBuilder<List<Patient>>(
                        future: DatabaseHelper.instance.getPatients(),
                        builder: (context, snapshot) {
                          String count = snapshot.hasData ? snapshot.data!.length.toString() : "0";
                          return _buildStatCard('Total Patients', count, Icons.people_alt_rounded, const Color(0xFF3B82F6), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsListScreen()))); 
                        },
                      ),
                      const SizedBox(width: 16),
                      FutureBuilder<List<Visit>>(
                        future: DatabaseHelper.instance.getAllVisits(),
                        builder: (context, snapshot) {
                          String count = snapshot.hasData ? snapshot.data!.length.toString() : "0";
                          return _buildStatCard('Total Visits', count, Icons.monitor_heart_rounded, const Color(0xFF10B981)); 
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 120), 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildQuickAction('New Patient', Icons.person_add_alt_1_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditPatientScreen())), isPrimary: true),
                  _buildQuickAction('My Patients', Icons.view_list_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsListScreen()))),
                  _buildQuickAction('Clinical Reports', Icons.analytics_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
                  _buildQuickAction('Settings', Icons.settings_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
