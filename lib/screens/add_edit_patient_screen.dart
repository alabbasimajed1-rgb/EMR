import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/database_helper.dart'; // استدعاء قاعدة البيانات المحلية

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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))
            ),
            backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.06),
            side: BorderSide(color: const Color(0xFF1E3A8A).withOpacity(0.15), width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
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

      Patient newPatient = Patient(
        id: widget.patient?.id,
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
          // استخدام قاعدة البيانات المحلية للإضافة
          await DatabaseHelper.instance.insertPatient(newPatient);
        } else {
          // استخدام قاعدة البيانات المحلية للتعديل
          await DatabaseHelper.instance.updatePatient(newPatient);
        }
        if (mounted) {
          Navigator.pop(context, true); // إرسال true لتحديث القائمة السابقة
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving patient: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required (*) fields'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.patient == null ? 'Add New Patient' : 'Edit Patient Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    _buildSectionCard(
                      title: 'Personal Information *',
                      icon: Icons.person_outline,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.badge_outlined)),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Age *', prefixIcon: Icon(Icons.cake_outlined)),
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                value: _gender,
                                decoration: const InputDecoration(labelText: 'Gender *', prefixIcon: Icon(Icons.wc_outlined)),
                                items: const [
                                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                                ],
                                onChanged: (value) => setState(() => _gender = value!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    _buildSectionCard(
                      title: 'Clinical Assessment',
                      icon: Icons.monitor_heart_outlined,
                      children: [
                        TextFormField(
                          controller: _chiefComplaintController,
                          decoration: const InputDecoration(labelText: 'Chief Complaint *', alignLabelWithHint: true),
                          maxLines: 2,
                          validator: (value) => value == null || value.isEmpty ? 'Required to open a file' : null,
                        ),
                        _buildTemplateChips(_chiefComplaintTpl, _chiefComplaintController),
                        const SizedBox(height: 24),
                        
                        TextFormField(
                          controller: _medicalHistoryController,
                          decoration: const InputDecoration(labelText: 'Medical History (Optional)', alignLabelWithHint: true),
                          maxLines: 2,
                        ),
                        _buildTemplateChips(_historyTpl, _medicalHistoryController),
                      ],
                    ),

                    _buildSectionCard(
                      title: 'Diagnostics (Optional)',
                      icon: Icons.biotech_outlined,
                      children: [
                        TextFormField(
                          controller: _investigationsController,
                          decoration: const InputDecoration(labelText: 'Investigations & Imaging', alignLabelWithHint: true),
                          maxLines: 2,
                        ),
                        _buildTemplateChips(_investigationsTpl, _investigationsController),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _diffDiagnosisController,
                          decoration: const InputDecoration(labelText: 'Differential Diagnosis', alignLabelWithHint: true),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _finalDiagnosisController,
                          decoration: const InputDecoration(labelText: 'Final Diagnosis', alignLabelWithHint: true),
                          maxLines: 2,
                        ),
                        _buildTemplateChips(_diagnosisTpl, _finalDiagnosisController),
                      ],
                    ),

                    _buildSectionCard(
                      title: 'Management Plan (Optional)',
                      icon: Icons.medical_services_outlined,
                      children: [
                        TextFormField(
                          controller: _treatmentPlanController,
                          decoration: const InputDecoration(labelText: 'Initial Treatment Plan', alignLabelWithHint: true),
                          maxLines: 3,
                        ),
                        _buildTemplateChips(_treatmentTpl, _treatmentPlanController),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _savePatient,
                        icon: const Icon(Icons.check_circle_outline, size: 24),
                        label: Text(
                          widget.patient == null ? 'Save Patient File' : 'Update Patient File',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
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
