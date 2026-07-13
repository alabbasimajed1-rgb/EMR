import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import 'add_edit_patient_screen.dart';
import 'report_screen.dart'; 
import 'login_screen.dart';
import 'patients_list_screen.dart'; 
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _doctorName = 'Clinic Doctor';
  String _doctorSpecialty = 'Medical Specialty';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // دالة سحب بيانات الطبيب من الإعدادات
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _doctorName = prefs.getString('doctor_name') ?? 'Clinic Doctor';
        _doctorSpecialty = prefs.getString('doctor_specialty') ?? 'Medical Specialty';
      });
    }
  }

  Future<int> _getPatientsCount() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM patients');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> _getVisitsCount() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM visits');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  void _refreshData() {
    _loadProfile(); // تحديث الاسم فوراً بعد العودة من الإعدادات
    setState(() {});
  }

  void _logout() {
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
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: isPrimary 
            ? [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]
            : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isPrimary ? Colors.white : const Color(0xFF1E3A8A)),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isPrimary ? Colors.white : const Color(0xFF1E293B)),
            ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dateString, style: TextStyle(color: Colors.blue.shade200, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Text(
                                  _doctorName, // يتم جلب الاسم هنا ديناميكياً
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _doctorSpecialty, // يتم جلب التخصص هنا ديناميكياً
                                  style: TextStyle(color: Colors.blue.shade100, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.lock_outline, color: Colors.white, size: 22),
                              onPressed: _logout,
                              tooltip: 'Secure Clinic', // تم تعديل الوصف هنا
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Positioned(
                  top: 170,
                  left: 24,
                  right: 24,
                  child: Row(
                    children: [
                      FutureBuilder<int>(
                        future: _getPatientsCount(),
                        builder: (context, snapshot) {
                          String count = snapshot.data?.toString() ?? "0";
                          return _buildStatCard(
                            'Total Patients', 
                            count, 
                            Icons.people_alt_rounded, 
                            const Color(0xFF3B82F6),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsListScreen())).then((_) => _refreshData()), 
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      FutureBuilder<int>(
                        future: _getVisitsCount(),
                        builder: (context, snapshot) {
                          String count = snapshot.data?.toString() ?? "0";
                          return _buildStatCard(
                            'Total Visits', 
                            count, 
                            Icons.monitor_heart_rounded, 
                            const Color(0xFF10B981),
                            onTap: () {}, 
                          );
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.blue.shade900)),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    childAspectRatio: 1.2,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildQuickAction(
                        'New Patient', 
                        Icons.person_add_alt_1_rounded, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditPatientScreen())).then((_) => _refreshData()),
                        isPrimary: true,
                      ),
                      _buildQuickAction(
                        'My Patients', 
                        Icons.view_list_rounded, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsListScreen())).then((_) => _refreshData()), 
                      ),
                      _buildQuickAction(
                        'Clinical Reports', 
                        Icons.analytics_rounded, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen())), 
                      ),
                      _buildQuickAction(
                        'Settings', 
                        Icons.settings_rounded, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())).then((_) => _refreshData()), 
                      ),
                    ],
                  ),
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
