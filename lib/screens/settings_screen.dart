import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_drive_service.dart';
import '../l10n/app_localizations.dart';
import '../main.dart'; 

class SettingsScreen extends StatefulWidget {
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
  String _currentLanguageCode = 'en';

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
    
    if (mounted) {
      MyApp.setLocale(context, Locale(langCode));
    }
    
    if (widget.onLocaleChange != null) {
      widget.onLocaleChange!(Locale(langCode));
    }
  }

  // --- دالة تغيير الرمز السري الجديدة ---
  Future<void> _showChangePinDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.changePin, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPinController,
                decoration: InputDecoration(labelText: l10n.currentPin, prefixIcon: const Icon(Icons.lock_outline)),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newPinController,
                decoration: InputDecoration(labelText: l10n.newPin, prefixIcon: const Icon(Icons.lock_reset)),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmPinController,
                decoration: InputDecoration(labelText: l10n.confirmNewPin, prefixIcon: const Icon(Icons.check_circle_outline)),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                
                // جلب الرمز القديم المحفوظ من الذاكرة (سواء كان مفتاحه pin أو user_pin)
                final savedPin = prefs.getString('pin') ?? prefs.getString('user_pin') ?? '';

                if (currentPinController.text != savedPin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.incorrectCurrentPin), backgroundColor: Colors.red),
                  );
                  return;
                }

                if (newPinController.text != confirmPinController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.pinsDoNotMatch), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                if (newPinController.text.length < 4) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN must be 4 digits'), backgroundColor: Colors.red), 
                  );
                  return;
                }

                // حفظ الرمز الجديد في نفس المفتاح الذي يستخدمه التطبيق
                if (prefs.containsKey('pin')) {
                  await prefs.setString('pin', newPinController.text);
                } else {
                  await prefs.setString('user_pin', newPinController.text);
                }
                
                if (context.mounted) {
                  Navigator.pop(context); // إغلاق النافذة
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.pinChangedSuccess), backgroundColor: Colors.green),
                  );
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performBackup() async {
    setState(() => _isBackingUp = true);
    final success = await _driveService.backupDatabase();
    setState(() => _isBackingUp = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? AppLocalizations.of(context)!.successSave : 'Backup failed. Please try again.'), 
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _performRestore() async {
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
            
            // --- قسم الأمان الجديد ---
            Text(l10n.security, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
              child: SizedBox(
                width: double.infinity, height: 50,
                child: OutlinedButton.icon(
                  onPressed: _showChangePinDialog,
                  icon: const Icon(Icons.password),
                  label: Text(l10n.changePin, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1E3A8A), side: const BorderSide(color: Color(0xFF1E3A8A)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ),

            const SizedBox(height: 32),

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
                            const Text('Securely save your patient records to your personal Google Drive.', style: TextStyle(color: Colors.grey, fontSize: 13)), 
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
