import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../services/database_helper.dart'; // استدعاء قاعدة البيانات المحلية

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

  Widget _buildTemplateChips(List<String> templates, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: templates.map((text) {
          return ActionChip(
            label: Text(
              text, 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F766E))
            ),
            backgroundColor: const Color(0xFF0F766E).withOpacity(0.08),
            side: BorderSide(color: const Color(0xFF0F766E).withOpacity(0.2), width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onPressed: () => _appendTemplate(controller, text),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1E3A8A)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isNextVisit) {
          _nextVisitDate = picked;
        } else {
          _visitDate = picked;
        }
      });
    }
  }

  void _saveVisit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Visit newVisit = Visit(
        id: '', // سيتم إنشاء المعرف تلقائياً في قاعدة البيانات المحلية
        patientId: widget.patientId,
        visitDate: _visitDate,
        procedure: _procedureController.text.trim(),
        investigations: _investigationsController.text.trim(),
        treatments: _treatmentsController.text.trim(),
        advices: _advicesController.text.trim(),
        nextVisitDate: _nextVisitDate,
      );

      try {
        // الحفظ محلياً باستخدام DatabaseHelper
        await DatabaseHelper.instance.insertVisit(newVisit);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visit recorded successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
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
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Color(0xFF1E3A8A), size: 28),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date of Visit', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  _visitDate.toString().substring(0, 10),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _investigationsController,
                            decoration: const InputDecoration(hintText: 'e.g., Lab tests, X-Rays...'),
                            maxLines: 2,
                          ),
                          _buildTemplateChips(_investigationsTemplates, _investigationsController),
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_available, color: _nextVisitDate == null ? Colors.grey : const Color(0xFF0F766E), size: 28),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Next Visit Date (Optional)', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  _nextVisitDate == null ? 'Not Scheduled' : _nextVisitDate!.toString().substring(0, 10),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _nextVisitDate == null ? Colors.grey : const Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (_nextVisitDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _nextVisitDate = null;
                                  });
                                },
                              )
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
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
