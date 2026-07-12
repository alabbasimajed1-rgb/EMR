import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../services/database_helper.dart';

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
      controller.text = currentText.isEmpty ? text : '$currentText, $text';
      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
    });
  }

  Widget _buildTemplateChips(List<String> templates, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Wrap(
        spacing: 8.0, runSpacing: 8.0,
        children: templates.map((text) {
          return ActionChip(
            label: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F766E))),
            backgroundColor: const Color(0xFF0F766E).withOpacity(0.08),
            onPressed: () => _appendTemplate(controller, text),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 20, color: const Color(0xFF1E3A8A)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))]),
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
      firstDate: DateTime(2000), lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isNextVisit) _nextVisitDate = picked; else _visitDate = picked;
      });
    }
  }

  void _saveVisit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // توليد ID فريد للزيارة
      String visitId = DateTime.now().millisecondsSinceEpoch.toString();

      Visit newVisit = Visit(
        id: visitId,
        patientId: widget.patientId,
        visitDate: _visitDate,
        procedure: _procedureController.text.trim(),
        investigations: _investigationsController.text.trim(),
        treatments: _treatmentsController.text.trim(),
        advices: _advicesController.text.trim(),
        nextVisitDate: _nextVisitDate,
      );

      try {
        await DatabaseHelper.instance.addVisit(newVisit);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit recorded!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Add Clinical Visit'), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(children: [
            InkWell(
              onTap: () => _selectDate(context, false),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: Row(children: [const Icon(Icons.calendar_month, color: Color(0xFF1E3A8A)), const SizedBox(width: 16), Text('Date: ${_visitDate.toString().substring(0, 10)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))]),
              ),
            ),
            const SizedBox(height: 24),
            _buildInputCard(title: 'Complaint / Procedure *', icon: Icons.monitor_heart_outlined, child: Column(children: [TextFormField(controller: _procedureController, validator: (v) => v!.isEmpty ? 'Required' : null), _buildTemplateChips(_procedureTemplates, _procedureController)])),
            _buildInputCard(title: 'Investigations', icon: Icons.biotech_outlined, child: Column(children: [TextFormField(controller: _investigationsController), _buildTemplateChips(_investigationsTemplates, _investigationsController)])),
            _buildInputCard(title: 'Treatments', icon: Icons.medication_outlined, child: Column(children: [TextFormField(controller: _treatmentsController), _buildTemplateChips(_treatmentsTemplates, _treatmentsController)])),
            _buildInputCard(title: 'Clinical Advices', icon: Icons.lightbulb_outline, child: Column(children: [TextFormField(controller: _advicesController), _buildTemplateChips(_advicesTemplates, _advicesController)])),
            
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _saveVisit, child: const Text('Save Visit Record'))),
          ]),
        ),
      ),
    );
  }
}
