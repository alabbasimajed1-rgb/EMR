import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_drive_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _doctorNameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final GoogleDriveService _driveService = GoogleDriveService();
  
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _doctorNameController.text = prefs.getString('doctor_name') ?? '';
      _specialtyController.text = prefs.getString('doctor_specialty') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('doctor_name', _doctorNameController.text.trim());
    await prefs.setString('doctor_specialty', _specialtyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully'), backgroundColor: Colors.green),
      );
    }
  }

  // --- دوال النسخ الاحتياطي والاستعادة ---
  Future<void> _performBackup() async {
    setState(() => _isBackingUp = true);
    final success = await _driveService.backupDatabase();
    setState(() => _isBackingUp = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Backup completed successfully!' : 'Backup failed. Please try again.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _performRestore() async {
    // نطلب تأكيداً من المستخدم قبل الاستعادة لأنها ستمسح البيانات الحالية
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text('This will OVERWRITE all your current app data with the data from Google Drive. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Yes, Restore', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRestoring = true);
    final success = await _driveService.restoreDatabase();
    setState(() => _isRestoring = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Data restored successfully! Please restart the app.' : 'Restore failed. No backup found or connection error.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Doctor Profile (For Reports)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                children: [
                  TextField(
                    controller: _doctorNameController,
                    decoration: InputDecoration(labelText: 'Doctor Name', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _specialtyController,
                    decoration: InputDecoration(labelText: 'Specialty / Department', prefixIcon: const Icon(Icons.medical_services_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Data & Cloud Backup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_done, color: Colors.green, size: 28),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Google Drive Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Securely save your patient records to your personal Google Drive.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isBackingUp || _isRestoring ? null : _performBackup,
                      icon: _isBackingUp ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload),
                      label: Text(_isBackingUp ? 'Uploading...' : 'Backup Data to Cloud'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isBackingUp || _isRestoring ? null : _performRestore,
                      icon: _isRestoring ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_download),
                      label: Text(_isRestoring ? 'Downloading...' : 'Restore Data from Cloud'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1E3A8A), side: const BorderSide(color: Color(0xFF1E3A8A)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _driveService.signOut(),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign out of Google'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
