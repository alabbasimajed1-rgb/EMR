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

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _chiefComplaintController;
  late TextEditingController _historyController;
  late TextEditingController _investigationController;
  late TextEditingController _diffDiagController;
  late TextEditingController _finalDiagController;
  late TextEditingController _treatmentController;

  String _gender = 'Male';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient?.fullName ?? '');
    _ageController = TextEditingController(text: widget.patient?.age.toString() ?? '');
    _phoneController = TextEditingController(text: widget.patient?.phoneNumber ?? '');
    _chiefComplaintController = TextEditingController(text: widget.patient?.chiefComplaint ?? '');
    _historyController = TextEditingController(text: widget.patient?.medicalHistory ?? '');
    _investigationController = TextEditingController(text: widget.patient?.investigationAndImaging ?? '');
    _diffDiagController = TextEditingController(text: widget.patient?.differentialDiagnosis ?? '');
    _finalDiagController = TextEditingController(text: widget.patient?.finalDiagnosis ?? '');
    _treatmentController = TextEditingController(text: widget.patient?.firstTreatmentPlan ?? '');

    if (widget.patient != null) {
      _gender = widget.patient!.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _chiefComplaintController.dispose();
    _historyController.dispose();
    _investigationController.dispose();
    _diffDiagController.dispose();
    _finalDiagController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  void _savePatient() async {
    if (_formKey.currentState!.validate()) {
      Patient newPatient = Patient(
        id: widget.patient?.id,
        fullName: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        phoneNumber: _phoneController.text.trim(),
        chiefComplaint: _chiefComplaintController.text.trim(),
        medicalHistory: _historyController.text.trim(),
        investigationAndImaging: _investigationController.text.trim(),
        differentialDiagnosis: _diffDiagController.text.trim(),
        finalDiagnosis: _finalDiagController.text.trim(),
        firstTreatmentPlan: _treatmentController.text.trim(),
        createdAt: widget.patient?.createdAt ?? DateTime.now(),
      );

      if (widget.patient == null) {
        await DatabaseHelper.instance.insertPatient(newPatient);
      } else {
        await DatabaseHelper.instance.updatePatient(newPatient);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _addTextToController(TextEditingController controller, String text) {
    setState(() {
      if (controller.text.isEmpty) {
        controller.text = text;
      } else {
        controller.text += ', $text';
      }
    });
  }

  Widget _buildChipGroup(List<String> options, TextEditingController controller) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return ActionChip(
          label: Text(option, style: TextStyle(fontSize: 12, color: Colors.blue.shade900)),
          backgroundColor: Colors.blue.shade50,
          side: BorderSide(color: Colors.blue.shade200),
          onPressed: () => _addTextToController(controller, option),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 20, color: Colors.blue.shade800),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.blue.shade900)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
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
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSectionCard(
                title: 'Personal Information *',
                icon: Icons.person_outline,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Full Name *', prefixIcon: const Icon(Icons.badge_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    validator: (value) => value!.isEmpty ? 'Please enter full name' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Age *', prefixIcon: const Icon(Icons.cake_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          validator: (value) => value!.isEmpty ? 'Required' : null,
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
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: 'Phone Number (Optional)', prefixIcon: const Icon(Icons.phone_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ],
              ),

              _buildSectionCard(
                title: 'Clinical Assessment',
                icon: Icons.monitor_heart_outlined,
                children: [
                  TextFormField(
                    controller: _chiefComplaintController,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: 'Chief Complaint', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),
                  _buildChipGroup(['Pre-op Assessment', 'Post-op complication', 'Shortness of breath', 'Decreased LOC', 'Trauma', 'Sepsis', 'Abdominal pain', 'Chest pain'], _chiefComplaintController),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _historyController,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: 'Medical History (Optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),
                  _buildChipGroup(['Heart Failure', 'Pneumonia', 'Appendicitis', 'Hypertension', 'Diabetes'], _historyController),
                ],
              ),

              _buildSectionCard(
                title: 'Management Plan',
                icon: Icons.medical_services_outlined,
                children: [
                  TextFormField(
                    controller: _treatmentController,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: 'Initial Treatment Plan (Optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),
                  _buildChipGroup(['Admit to ICU', 'Mechanical Ventilation', 'Inotropic Support', 'IV Fluids Resuscitation', 'Broad-spectrum Antibiotics', 'Prepare for OR', 'Conservative Management'], _treatmentController),
                ],
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _savePatient,
                  icon: const Icon(Icons.check_circle_outline, size: 28),
                  label: const Text('Save Patient File', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
