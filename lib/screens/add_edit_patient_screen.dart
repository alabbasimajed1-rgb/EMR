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

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  String _gender = 'Male';

  final _chiefComplaintController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _investigationController = TextEditingController();
  final _differentialDiagnosisController = TextEditingController();
  final _finalDiagnosisController = TextEditingController();
  final _firstTreatmentPlanController = TextEditingController();

  bool _isLoading = false;

  // القوائم السريعة (Templates) مطابقة للصور تماماً
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

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
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
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
        if (widget.patient == null) {
          await DatabaseHelper.instance.insertPatient(patient);
        } else {
          await DatabaseHelper.instance.updatePatient(patient);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient saved successfully!'), backgroundColor: Colors.green),
          );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.patient == null ? 'Add New Patient' : 'Edit Patient', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      title: 'Personal Information *',
                      icon: Icons.person_outline,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'Full Name *', prefixIcon: const Icon(Icons.badge_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter patient name' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ageController,
                                decoration: InputDecoration(labelText: 'Age *', prefixIcon: const Icon(Icons.cake_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Required';
                                  if (int.tryParse(value) == null) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _gender,
                                decoration: InputDecoration(labelText: 'Gender *', prefixIcon: const Icon(Icons.people_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                                items: ['Male', 'Female'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                                onChanged: (newValue) => setState(() => _gender = newValue!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(labelText: 'Phone Number (Optional)', prefixIcon: const Icon(Icons.phone_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),

                    _buildSectionCard(
                      title: 'Clinical Assessment',
                      icon: Icons.monitor_heart_outlined,
                      children: [
                        TextFormField(
                          controller: _chiefComplaintController,
                          decoration: InputDecoration(labelText: 'Chief Complaint *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          maxLines: 3,
                          validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
                        ),
                        _buildTemplateChips(_ccTemplates, _chiefComplaintController),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _medicalHistoryController,
                          decoration: InputDecoration(labelText: 'Medical History (Optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          maxLines: 3,
                        ),
                        _buildTemplateChips(_hxTemplates, _medicalHistoryController),
                      ],
                    ),

                    _buildSectionCard(
                      title: 'Diagnostics (Optional)',
                      icon: Icons.biotech_outlined,
                      children: [
                        TextFormField(
                          controller: _investigationController,
                          decoration: InputDecoration(labelText: 'Investigations & Imaging', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          maxLines: 3,
                        ),
                        _buildTemplateChips(_invTemplates, _investigationController),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _differentialDiagnosisController,
                          decoration: InputDecoration(labelText: 'Differential Diagnosis', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _finalDiagnosisController,
                          decoration: InputDecoration(labelText: 'Final Diagnosis', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          maxLines: 3,
                        ),
                        _buildTemplateChips(_dxTemplates, _finalDiagnosisController),
                      ],
                    ),

                    _buildSectionCard(
                      title: 'Management Plan (Optional)',
                      icon: Icons.medical_services_outlined,
                      children: [
                        TextFormField(
                          controller: _firstTreatmentPlanController,
                          decoration: InputDecoration(labelText: 'Initial Treatment Plan', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
                        label: const Text('Save Patient File', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
