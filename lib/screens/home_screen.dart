import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'add_patient_screen.dart';
// import 'patients_list_screen.dart'; // قم بتفعيلها لاحقاً
// import 'reports_screen.dart'; // قم بتفعيلها لاحقاً
// import 'settings_screen.dart'; // قم بتفعيلها لاحقاً

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalPatients = 0;
  int totalVisits = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final dbHelper = DatabaseHelper.instance;
    final patients = await dbHelper.getAllPatients();
    
    // حساب إجمالي الزيارات لجميع المرضى
    int visitsCount = 0;
    for (var patient in patients) {
      final visits = await dbHelper.getVisitsForPatient(patient.id!);
      visitsCount += visits.length;
    }

    if (mounted) {
      setState(() {
        totalPatients = patients.length;
        totalVisits = visitsCount;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildStatisticsCards(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                    _buildQuickActions(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${DateTime.now().day} ${_getMonth(DateTime.now().month)} ${DateTime.now().year}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  // سيتم إضافة كود تسجيل الخروج لاحقاً
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Dr. Majed Abbas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Consultant Anesthesia & Intensive Care',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Total Patients', totalPatients.toString(), Icons.people, Colors.blue)),
          const SizedBox(width: 15),
          Expanded(child: _buildStatCard('Total Visits', totalVisits.toString(), Icons.monitor_heart, Colors.green)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 15),
          Text(
            count,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        children: [
          _buildActionCard(
            context,
            'New Patient',
            Icons.person_add,
            const Color(0xFF2E5BFF),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPatientScreen())).then((_) => _loadStatistics()),
          ),
          _buildActionCard(
            context,
            'My Patients',
            Icons.list_alt,
            Colors.white,
            () {}, // سيتم التوجيه لشاشة المرضى
            isPrimary: false,
          ),
          _buildActionCard(
            context,
            'Clinical Reports',
            Icons.bar_chart,
            Colors.white,
            () {}, // سيتم التوجيه للتقارير
            isPrimary: false,
          ),
          _buildActionCard(
            context,
            'Settings',
            Icons.settings,
            Colors.white,
            () {}, // سيتم التوجيه للإعدادات
            isPrimary: false,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color bgColor, VoidCallback onTap, {bool isPrimary = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isPrimary
              ? [BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))]
              : [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: isPrimary ? Colors.white : const Color(0xFF1E3A8A)),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.white : const Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
