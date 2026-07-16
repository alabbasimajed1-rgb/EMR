import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/visit.dart';
import '../services/database_helper.dart'; 
import '../services/google_drive_service.dart';

class NewVisitScreen extends StatefulWidget {
  final String patientId;

  const NewVisitScreen({super.key, required this.patientId});

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _procedureController = TextEditingController();
  final TextEditingController _investigationsController = TextEditingController();
  final TextEditingController _treatmentsController = TextEditingController();
  final TextEditingController _advicesController = TextEditingController();

  DateTime _visitDate = DateTime.now();
  DateTime? _nextVisitDate;
  bool _isLoading = false;

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _procedureTemplates = ['Consultation', 'Follow-up', 'ICU Admission', 'General Anesthesia', 'Spinal Anesthesia', 'Peribulbar Anesthesia', 'Epidural', 'Sedation'];
  final List<String> _investigationsTemplates = ['CBC', 'KFT', 'LFT', 'ECG', 'CXR', 'ABG', 'Echo', 'Coagulation Profile', 'CT Scan'];
  final List<String> _treatmentsTemplates = ['IV Fluids', 'Broad-spectrum Antibiotics', 'Analgesics', 'Antiemetics', 'Inotropes', 'Paracetamol'];
  final List<String> _advicesTemplates = ['NPO for 8 hours', 'Strict bed rest', 'Monitor Vitals closely', 'Follow up after 1 week'];

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
           final currentText = _investigationsController.text;
           setState(() {
             _investigationsController.text = currentText.isEmpty 
                 ? recognizedText.text 
                 : '$currentText\n\n${recognizedText.text}';
           });
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text extracted successfully!'), backgroundColor: Colors.green));
           }
        } else {
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No text found in the image.'), backgroundColor: Colors.orange));
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error taking picture: $e')));
      }
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
              title: const Text('Take a Photo (Camera)'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF1E3A8A)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                          // ==============================================================
          // النسخ الاحتياطي التلقائي (في الخلفية بصمت)
          // ==============================================================
          Future.microtask(() async {
            try {
              // إنشاء نسخة من خدمة جوجل درايف ثم استدعاء دالة الرفع
              final driveService = GoogleDriveService();
              await driveService.backupDatabase();
              
              debugPrint("Silent backup completed successfully after saving patient."); 
            } catch (e) {
              debugPrint("Silent backup failed: $e"); 
            }
          });
          // ==============================================================

                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateChips(List<String> templates, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: templates.map((text) {
          return ActionChip(
            label: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F766E))),
            backgroundColor: const Color(0xFF0F766E).withOpacity(0.08),
            side: BorderSide(color: const Color(0xFF0F766E).withOpacity(0.2), width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onPressed: () => _appendTemplate(controller, text),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputCard({required String title, required IconData icon, required Widget child, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
                Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isNextVisit) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isNextVisit ? (_nextVisitDate ?? DateTime.now().add(const Duration(days: 7))) : _visitDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF1E3A8A))), child: child!);
      },
    );
    if (picked != null) {
      setState(() {
        if (isNextVisit) _nextVisitDate = picked;
        else _visitDate = picked;
      });
    }
  }

  void _saveVisit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Visit newVisit = Visit(
        id: null, 
        patientId: int.parse(widget.patientId), 
        visitDate: _visitDate,
        procedure: _procedureController.text.trim(),
        investigations: _investigationsController.text.trim(),
        treatments: _treatmentsController.text.trim(),
        advices: _advicesController.text.trim(),
        nextVisitDate: _nextVisitDate?.toString(), 
      );

      try {
        int newVisitId = await DatabaseHelper.instance.insertVisit(newVisit);
        
        if (_selectedImages.isNotEmpty) {
          final directory = await getApplicationDocumentsDirectory();
          for (var image in _selectedImages) {
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';
            final savedImage = await image.copy('${directory.path}/$fileName');
            await DatabaseHelper.instance.insertImage(newVisitId, savedImage.path);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visit and files saved successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Add Clinical Visit', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.1))),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Color(0xFF1E3A8A), size: 28),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date of Visit', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(_visitDate.toString().substring(0, 10), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.edit, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildInputCard(
                      title: 'Complaint / Procedure *',
                      icon: Icons.monitor_heart_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _procedureController,
                            decoration: const InputDecoration(hintText: 'e.g., General Anesthesia, Follow-up...'),
                            maxLines: 2,
                            validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
                          ),
                          _buildTemplateChips(_procedureTemplates, _procedureController),
                        ],
                      ),
                    ),

                    _buildInputCard(
                      title: 'Investigations & Imaging',
                      icon: Icons.biotech_outlined,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // زر الـ OCR الجديد للزيارات
                          IconButton(
                            icon: const Icon(Icons.document_scanner_outlined, color: Color(0xFF1E3A8A)),
                            tooltip: 'Scan Text from Document',
                            onPressed: _scanTextFromImage,
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1)),
                          ),
                          const SizedBox(width: 8),
                          // زر الكاميرا للصور
                          IconButton(
                            icon: const Icon(Icons.camera_alt, color: Color(0xFF0F766E)),
                            tooltip: 'Attach Documents',
                            onPressed: _showImageSourceDialog,
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF0F766E).withOpacity(0.1)),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _investigationsController,
                            decoration: const InputDecoration(hintText: 'e.g., Lab tests, X-Rays...'),
                            maxLines: 2,
                          ),
                          _buildTemplateChips(_investigationsTemplates, _investigationsController),
                          
                          if (_selectedImages.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text('Attached Documents:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
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
                          ]
                        ],
                      ),
                    ),

                    _buildInputCard(
                      title: 'Treatments Prescribed',
                      icon: Icons.medication_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _treatmentsController,
                            decoration: const InputDecoration(hintText: 'e.g., Medications, IV Fluids...'),
                            maxLines: 2,
                          ),
                          _buildTemplateChips(_treatmentsTemplates, _treatmentsController),
                        ],
                      ),
                    ),

                    _buildInputCard(
                      title: 'Clinical Advices',
                      icon: Icons.lightbulb_outline,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _advicesController,
                            decoration: const InputDecoration(hintText: 'e.g., Instructions for patient...'),
                            maxLines: 2,
                          ),
                          _buildTemplateChips(_advicesTemplates, _advicesController),
                        ],
                      ),
                    ),

                    InkWell(
                      onTap: () => _selectDate(context, true),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid)),
                        child: Row(
                          children: [
                            Icon(Icons.event_available, color: _nextVisitDate == null ? Colors.grey : const Color(0xFF0F766E), size: 28),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Next Visit Date (Optional)', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(_nextVisitDate == null ? 'Not Scheduled' : _nextVisitDate!.toString().substring(0, 10), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _nextVisitDate == null ? Colors.grey : const Color(0xFF1E293B))),
                              ],
                            ),
                            const Spacer(),
                            if (_nextVisitDate != null)
                              IconButton(icon: const Icon(Icons.clear, color: Colors.red, size: 20), onPressed: () => setState(() => _nextVisitDate = null))
                            else
                              const Icon(Icons.add_circle_outline, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _saveVisit,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Visit Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
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
