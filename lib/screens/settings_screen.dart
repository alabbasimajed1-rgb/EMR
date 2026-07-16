import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_drive_service.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  // نضيف هنا خاصية لتلقي دالة تغيير اللغة من الشاشة الرئيسية إذا لزم الأمر
  final Function(Locale)? onLocaleChange;
  
  const SettingsScreen({super.key, this.onLocaleChange});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _doctorNameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final GoogleDriveService _driveService = GoogleDriveService();
  
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String _currentLanguageCode = 'en'; // اللغة الافتراضية

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
      _currentLanguageCode = prefs.getString('language_code') ?? 'en';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('doctor_name', _doctorNameController.text.trim());
    await prefs.setString('doctor_specialty', _specialtyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.successSave), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _changeLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);
    setState(() {
      _currentLanguageCode = langCode;
    });
    
    // استدعاء دالة تغيير اللغة لتحديث التطبيق بالكامل
    if (widget.onLocaleChange != null) {
      widget.onLocaleChange!(Locale(langCode));
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
          content: Text(success ? AppLocalizations.of(context)!.successSave : 'Backup failed. Please try again.'), // يمكن إضافة الترجمة للفشل لاحقاً
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _performRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'), // يمكن ترجمته لاحقاً
        content: const Text('This will OVERWRITE all your current app data with the data from Google Drive. Are you sure?'), // يمكن ترجمته لاحقاً
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
          content: Text(success ? 'Data restored successfully! Please restart the app.' : 'Restore failed. No backup found or connection error.'), // يمكن ترجمته لاحقاً
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // اختصار لسهولة الوصول للقاموس
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(l10n.settings, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            // --- قسم تغيير اللغة الجديد ---
            Text('Language / اللغة', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentLanguageCode,
                  isExpanded: true,
                  icon: const Icon(Icons.language, color: Color(0xFF1E3A8A)),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _changeLanguage(newValue);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- الملف الشخصي للطبيب ---
            Text(l10n.doctorProfile, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                children: [
                  TextField(
                    controller: _doctorNameController,
                    decoration: InputDecoration(labelText: l10n.doctorName, prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _specialtyController,
                    decoration: InputDecoration(labelText: l10n.specialty, prefixIcon: const Icon(Icons.medical_services_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text(l10n.saveProfile, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            // --- النسخ الاحتياطي السحابي ---
            Text(l10n.dataCloudBackup, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_done, color: Colors.green, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.googleDriveBackup, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Securely save your patient records to your personal Google Drive.', style: const TextStyle(color: Colors.grey, fontSize: 13)), // يمكن ترجمته لاحقاً
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
                      label: Text(_isBackingUp ? 'Uploading...' : l10n.backupToCloud),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isBackingUp || _isRestoring ? null : _performRestore,
                      icon: _isRestoring ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_download),
                      label: Text(_isRestoring ? 'Downloading...' : l10n.restoreFromCloud),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1E3A8A), side: const BorderSide(color: Color(0xFF1E3A8A)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _driveService.signOut(),
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(l10n.signOut),
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
