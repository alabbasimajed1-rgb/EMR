import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/database_helper.dart';

class AddEditPatientScreen extends StatefulWidget {
  final Patient? patient;

  const AddEditPatientScreen({super.key, this.patient});

  @override
  State<AddEditPatientScreen> createState() => _AddEditPatientScreenState();
}

class _AddEditPatientScreenState extends State<AddEditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _gender = 'Male';
  final TextEditingController _chiefComplaintController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();
  final TextEditingController _investigationsController = TextEditingController();
  final TextEditingController _diffDiagnosisController = TextEditingController();
  final TextEditingController _finalDiagnosisController = TextEditingController();
  final TextEditingController _treatmentPlanController = TextEditingController();

  bool _isLoading = false;

  final List<String> _chiefComplaintTpl = ['Pre-op Assessment', 'Post-op complication', 'Shortness of breath', 'Decreased LOC', 'Trauma', 'Sepsis', 'Abdominal pain', 'Chest pain'];
  final List<String> _historyTpl = ['HTN', 'DM Type 2', 'IHD', 'Asthma', 'COPD', 'CKD', 'Smoker', 'No chronic illnesses'];
  final List<String> _investigationsTpl = ['CBC', 'KFT', 'LFT', 'ECG', 'CXR', 'ABG', 'Coagulation Profile', 'Echocardiography', 'CT Brain'];
  final List<String> _diagnosisTpl = ['Respiratory Failure', 'Septic Shock', 'Post-op Recovery', 'Acute Kidney Injury', 'Heart Failure', 'Pneumonia', 'Appendicitis'];
  final List<String> _treatmentTpl = ['Admit to ICU', 'Mechanical Ventilation', 'Inotropic Support', 'IV Fluids Resuscitation', 'Broad-spectrum Antibiotics', 'Prepare for OR', 'Conservative Management'];

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _nameController.text = widget.patient!.fullName;
      _ageController.text = widget.patient!.age.toString();
      _gender = widget.patient!.gender;
      _chiefComplaintController.text = widget.patient!.chiefComplaint;
      _medicalHistoryController.text = widget.patient!.medicalHistory;
      _investigationsController.text = widget.patient!.investigationAndImaging;
      _diffDiagnosisController.text = widget.patient!.differentialDiagnosis;
      _finalDiagnosisController.text = widget.patient!.finalDiagnosis;
      _treatmentPlanController.text = widget.patient!.firstTreatmentPlan;
    }
  }

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
            label: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
            backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.06),
            onPressed: () => _appendTemplate(controller, text),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 20, color: const Color(0xFF1E3A8A)), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
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

      // إنشاء كائن المريض الجديد
      Patient newPatient = Patient(
        id: widget.patient?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        gender: _gender,
        firstVisitDate: widget.patient?.firstVisitDate ?? DateTime.now(),
        chiefComplaint: _chiefComplaintController.text.trim(),
        medicalHistory: _medicalHistoryController.text.trim(),
        investigationAndImaging: _investigationsController.text.trim(),
        differentialDiagnosis: _diffDiagnosisController.text.trim(),
        finalDiagnosis: _finalDiagnosisController.text.trim(),
        firstTreatmentPlan: _treatmentPlanController.text.trim(),
      );

      try {
        if (widget.patient == null) {
          // إضافة جديد
          await DatabaseHelper.instance.addPatient(newPatient);
        } else {
          // تحديث
          await DatabaseHelper.instance.updatePatient(newPatient);
        }
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(widget.patient == null ? 'Add New Patient' : 'Edit Patient'), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(key: _formKey, child: Column(children: [
          _buildSectionCard(title: 'Personal Information *', icon: Icons.person_outline, children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name *')),
            const SizedBox(height: 16),
            TextFormField(controller: _ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age *')),
            DropdownButtonFormField<String>(value: _gender, items: const [DropdownMenuItem(value: 'Male', child: Text('Male')), DropdownMenuItem(value: 'Female', child: Text('Female'))], onChanged: (v) => setState(() => _gender = v!)),
          ]),
          _buildSectionCard(title: 'Clinical Assessment', icon: Icons.monitor_heart_outlined, children: [
            TextFormField(controller: _chiefComplaintController, decoration: const InputDecoration(labelText: 'Chief Complaint *')),
            _buildTemplateChips(_chiefComplaintTpl, _chiefComplaintController),
            TextFormField(controller: _medicalHistoryController, decoration: const InputDecoration(labelText: 'Medical History')),
            _buildTemplateChips(_historyTpl, _medicalHistoryController),
          ]),
          // يمكنك إكمال باقي البطاقات بنفس الطريقة
          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _savePatient, child: const Text("Save Patient"))),
        ])),
      ),
    );
  }
}
