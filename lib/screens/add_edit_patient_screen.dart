import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/patient.dart';
import '../services/database_helper.dart';
import '../services/google_drive_service.dart';
import '../l10n/app_localizations.dart';

class AddEditPatientScreen extends StatefulWidget {
  final Patient? patient;

  const AddEditPatientScreen({super.key, this.patient});

  @override
  State<AddEditPatientScreen> createState() => _AddEditPatientScreenState();
}

class _AddEditPatientScreenState extends State<AddEditPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  String _gender = 'Male'; // سنقوم بمعالجتها في البناء لتتوافق مع الترجمة

  final _chiefComplaintController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _investigationController = TextEditingController();
  final _differentialDiagnosisController = TextEditingController();
  final _finalDiagnosisController = TextEditingController();
  final _firstTreatmentPlanController = TextEditingController();

  bool _isLoading = false;

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _ccTemplates = ['Pre-op Assessment', 'Post-op complication', 'Shortness of breath', 'Decreased LOC', 'Trauma', 'Sepsis', 'Abdominal pain', 'Chest pain'];
  final List<String> _hxTemplates = ['HTN', 'DM Type 2', 'IHD', 'Asthma', 'COPD', 'CKD', 'Smoker', 'No chronic illnesses'];
  final List<String> _invTemplates = ['CBC', 'KFT', 'LFT', 'ECG', 'CXR', 'ABG', 'Coagulation Profile', 'Echocardiography', 'CT Brain'];
  final List<String> _dxTemplates = ['Respiratory Failure', 'Septic Shock', 'Post-op Recovery', 'Acute Kidney Injury', 'Heart Failure', 'Pneumonia', 'Appendicitis'];
  final List<String> _rxTemplates = ['Admit to ICU', 'Mechanical Ventilation', 'Inotropic Support', 'IV Fluids Resuscitation', 'Broad-spectrum Antibiotics', 'Prepare for OR', 'Conservative Management'];

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _nameController.text = widget.patient!.fullName;
      _ageController.text = widget.patient!.age.toString();
      _phoneController.text = widget.patient!.phoneNumber;
      _gender = widget.patient!.gender;
      
      _chiefComplaintController.text = widget.patient!.chiefComplaint;
      _medicalHistoryController.text = widget.patient!.medicalHistory;
      _investigationController.text = widget.patient!.investigationAndImaging;
      _differentialDiagnosisController.text = widget.patient!.differentialDiagnosis;
      _finalDiagnosisController.text = widget.patient!.finalDiagnosis;
      _firstTreatmentPlanController.text = widget.patient!.firstTreatmentPlan;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _chiefComplaintController.dispose();
    _medicalHistoryController.dispose();
    _investigationController.dispose();
    _differentialDiagnosisController.dispose();
    _finalDiagnosisController.dispose();
    _firstTreatmentPlanController.dispose();
    super.dispose();
  }

  // --- دالة استخراج النص من الصورة (OCR) ---
  Future<void> _scanTextFromImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
      if (pickedFile != null) {
        setState(() => _isLoading = true);
        
        final inputImage = InputImage.fromFilePath(pickedFile.path);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        
        await textRecognizer.close();
        
        if (recognizedText.text.isNotEmpty) {
           final currentText = _investigationController.text;
           setState(() {
             _investigationController.text = currentText.isEmpty 
                 ? recognizedText.text 
                 : '$currentText\n\n${recognizedText.text}';
           });
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text extracted successfully!'), backgroundColor: Colors.green)); // يمكن ترجمتها لاحقاً
           }
        } else {
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No text found in the image.'), backgroundColor: Colors.orange)); // يمكن ترجمتها لاحقاً
           }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error scanning text: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error taking picture: $e')));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1E3A8A)),
              title: const Text('Take a Photo (Camera)'), // يمكن ترجمتها لاحقاً
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF1E3A8A)),
              title: const Text('Choose from Gallery'), // يمكن ترجمتها لاحقاً
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _appendTemplate(TextEditingController controller, String text) {
    final currentText = controller.text;
    setState(() {
      if (currentText.isEmpty) {
        controller.text = text;
      } else {
        controller.text = '$currentText, $text';
      }
      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
    });
  }

  Widget _buildTemplateChips(List<String> templates, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: templates.map((text) {
          return ActionChip(
            label: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
            backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.08),
            side: BorderSide(color: const Color(0xFF1E3A8A).withOpacity(0.2), width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onPressed: () => _appendTemplate(controller, text),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, Widget? trailing, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  void _savePatient() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Patient patient = Patient(
        id: widget.patient?.id,
        fullName: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        phoneNumber: _phoneController.text.trim(),
        chiefComplaint: _chiefComplaintController.text.trim(),
        medicalHistory: _medicalHistoryController.text.trim(),
        investigationAndImaging: _investigationController.text.trim(),
        differentialDiagnosis: _differentialDiagnosisController.text.trim(),
        finalDiagnosis: _finalDiagnosisController.text.trim(),
        firstTreatmentPlan: _firstTreatmentPlanController.text.trim(),
        createdAt: widget.patient?.createdAt ?? DateTime.now(),
      );

      try {
        int patientIdToUse;
        if (widget.patient == null) {
          patientIdToUse = await DatabaseHelper.instance.insertPatient(patient);
        } else {
          await DatabaseHelper.instance.updatePatient(patient);
          patientIdToUse = widget.patient!.id!;
        }

        if (_selectedImages.isNotEmpty) {
          final directory = await getApplicationDocumentsDirectory();
          for (var image in _selectedImages) {
            final fileName = 'baseline_${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';
            final savedImage = await image.copy('${directory.path}/$fileName');
            await DatabaseHelper.instance.insertPatientImage(patientIdToUse, savedImage.path);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.successSave), backgroundColor: Colors.green),
          );
          
          Future.microtask(() async {
            try {
              final driveService = GoogleDriveService();
              await driveService.backupDatabase();
              debugPrint("Silent backup completed successfully after saving patient."); 
            } catch (e) {
              debugPrint("Silent backup failed: $e"); 
            }
          });

          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving patient: $e'), backgroundColor: Colors.red));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // اختصار للوصول للقاموس
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.patient == null ? l10n.addNewPatient : l10n.editPatient, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSectionCard(
                      title: l10n.personalInformation,
                      icon: Icons.person_outline,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: '${l10n.fullName} *', prefixIcon: const Icon(Icons.badge_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          validator: (value) => value == null || value.isEmpty ? l10n.requiredField : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ageController,
                                decoration: InputDecoration(labelText: '${l10n.age} *', prefixIcon: const Icon(Icons.cake_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return l10n.requiredField;
                                  if (int.tryParse(value) == null) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _gender,
                                decoration: InputDecoration(labelText: '${l10n.gender} *', prefixIcon: const Icon(Icons.people_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                                items: [
                                  DropdownMenuItem(value: 'Male', child: Text(l10n.male)),
                                  DropdownMenuItem(value: 'Female', child: Text(l10n.female)),
                                ].toList(),
                                onChanged: (newValue) => setState(() => _gender = newValue!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(labelText: '${l10n.phoneNumber} ${l10n.optional}', prefixIcon: const Icon(Icons.phone_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),

                    _buildSectionCard(
                      title: l10n.clinicalAssessment,
                      icon: Icons.monitor_heart_outlined,
                      children: [
                        TextFormField(
                          controller: _chiefComplaintController,
                          decoration: InputDecoration(labelText: '${l10n.chiefComplaint} *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          maxLines: 3,
                          validator: (value) => value == null || value.isEmpty ? l10n.requiredField : null,
                        ),
                        _buildTemplateChips(_ccTemplates, _chiefComplaintController),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _medicalHistoryController,
                          decoration: InputDecoration(labelText: '${l10n.medicalHistory} ${l10n.optional}', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          maxLines: 3,
                        ),
                        _buildTemplateChips(_hxTemplates, _medicalHistoryController),
                      ],
                    ),

                    _buildSectionCard(
                      title: l10n.diagnostics,
                      icon: Icons.biotech_outlined,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.document_scanner_outlined, color: Color(0xFF1E3A8A)),
                            tooltip: 'Scan Text from Document',
                            onPressed: _scanTextFromImage,
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1)),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.camera_alt, color: Color(0xFF0F766E)),
                            tooltip: 'Attach Baseline Documents',
                            onPressed: _showImageSourceDialog,
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF0F766E).withOpacity(0.1)),
                          ),
                        ],
                      ),
                      children: [
                        TextFormField(
                          controller: _investigationController,
                          decoration: InputDecoration(labelText: l10n.investigationsImaging, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          maxLines: 3,
                        ),
                        _buildTemplateChips(_invTemplates, _investigationController),
                        
                        if (_selectedImages.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Attached Documents:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)), // يمكن ترجمتها لاحقاً
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 90,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 12, top: 8),
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    Positioned(
                                      right: 4, top: 0,
                                      child: InkWell(
                                        onTap: () => setState(() => _selectedImages.removeAt(index)),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _differentialDiagnosisController,
                          decoration: InputDecoration(labelText: l10n.differentialDiagnosis, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _finalDiagnosisController,
                          decoration: InputDecoration(labelText: l10n.finalDiagnosis, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          maxLines: 3,
                        ),
                        _buildTemplateChips(_dxTemplates, _finalDiagnosisController),
                      ],
                    ),

                    _buildSectionCard(
                      title: l10n.managementPlan,
                      icon: Icons.medical_services_outlined,
                      children: [
                        TextFormField(
                          controller: _firstTreatmentPlanController,
                          decoration: InputDecoration(labelText: l10n.initialTreatmentPlan, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          maxLines: 3,
                        ),
                        _buildTemplateChips(_rxTemplates, _firstTreatmentPlanController),
                      ],
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _savePatient,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(l10n.savePatientFile, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
