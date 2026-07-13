import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _drNameController = TextEditingController();
  final _specialtyController = TextEditingController();
  bool _isLoadingBackup = false;

  @override
  void initState() {
    super.initState();
    _loadClinicData();
  }

  Future<void> _loadClinicData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _drNameController.text = prefs.getString('dr_name') ?? 'Dr. Majed Abbas';
      _specialtyController.text = prefs.getString('specialty') ?? 'Consultant Anesthesia & Intensive Care';
    });
  }

  Future<void> _saveClinicData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dr_name', _drNameController.text);
    await prefs.setString('specialty', _specialtyController.text);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clinic Profile Saved Successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // محاكاة عملية النسخ الاحتياطي - سيتم برمجتها لتعمل مع Google Drive في الخطوة القادمة
  Future<void> _runBackup() async {
    setState(() => _isLoadingBackup = true);
    await Future.delayed(const Duration(seconds: 2)); 
    setState(() => _isLoadingBackup = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Data backed up to cloud securely! (Simulated)'),
            ],
          ),
          backgroundColor: Colors.blue.shade700,
        ),
      );
    }
  }

  void _logout() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Settings & Profile'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text('ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.security, color: Colors.blue),
              ),
              title: const Text('Local Storage Status'),
              subtitle: Text('Secured & Offline', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text('CLINIC PROFILE (PDF HEADER)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _drNameController,
                    decoration: const InputDecoration(
                      labelText: 'Doctor Name',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _specialtyController,
                    decoration: const InputDecoration(
                      labelText: 'Specialty',
                      prefixIcon: Icon(Icons.local_hospital),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveClinicData,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade700,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text('DATA MANAGEMENT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload, color: Colors.green),
                  title: const Text('Backup Database'),
                  subtitle: const Text('Save a secure copy to Drive'),
                  trailing: _isLoadingBackup 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _isLoadingBackup ? null : _runBackup,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.blue),
                  title: const Text('App Language'),
                  trailing: const Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.lock),
              label: const Text('Lock App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
