import 'package:flutter/material.dart';
import 'login.screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Data Management'),
          _buildListTile(
            icon: Icons.cloud_upload,
            title: 'Backup to Google Drive',
            subtitle: 'Save a secure copy of your database',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Google Drive Backup coming soon!')),
              );
            },
          ),
          _buildListTile(
            icon: Icons.cloud_download,
            title: 'Restore from Google Drive',
            subtitle: 'Restore your data from a previous backup',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Google Drive Restore coming soon!')),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Security'),
          _buildListTile(
            icon: Icons.password,
            title: 'Change PIN Code',
            subtitle: 'Update your application access code',
            onTap: () {
              // سيتم برمجة تغيير الرمز السري لاحقاً
            },
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () {
              // تسجيل الخروج والعودة لشاشة القفل
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Lock Application', style: TextStyle(color: Colors.white, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF1E3A8A)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
