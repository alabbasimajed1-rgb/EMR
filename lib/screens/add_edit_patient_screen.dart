import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/database_helper.dart';

class AddPatientScreen extends StatefulWidget {
  final Patient? patient; // في حال أردنا استخدام نفس الشاشة للتعديل لاحقاً

  const AddPatientScreen({super.key, this.patient});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _contactController;
  String _selectedGender = 'Male';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient?.name ?? '');
    _ageController = TextEditingController(text: widget.patient?.age.toString() ?? '');
    _contactController = TextEditingController(text: widget.patient?.contact ?? '');
    if (widget.patient != null) {
      _selectedGender = widget.patient!.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newPatient = Patient(
        id: widget.patient?.id, // إذا كان تعديلاً سيحتفظ بنفس الـ ID
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender,
        contact: _contactController.text.trim(),
        createdAt: widget.patient?.createdAt ?? DateTime.now(),
      );

      try {
        // الحفظ في قاعدة البيانات المحلية بدلاً من Firebase
        await DatabaseHelper.instance.createPatient(newPatient);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient saved successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // العودة للشاشة السابقة وتحديثها
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.patient == null ? 'Add New Patient' : 'Edit Patient', 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Personal Information *', Icons.person),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name *',
                      icon: Icons.badge_outlined,
                      validator: (value) => value!.isEmpty ? 'Please enter patient name' : null,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _ageController,
                            label: 'Age *',
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                            validator: (value) => value!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildDropdown(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _contactController,
                      label: 'Contact Number (Optional)',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _savePatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Save Patient',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender *',
        prefixIcon: Icon(Icons.people_outline, color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Male', 'Female'].map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedGender = newValue!;
        });
      },
    );
  }
}
