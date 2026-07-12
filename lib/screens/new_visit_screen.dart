import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../services/database_helper.dart';
import 'package:intl/intl.dart';

class NewVisitScreen extends StatefulWidget {
  final String patientId;

  const NewVisitScreen({super.key, required this.patientId});

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen> {
  final _procedureController = TextEditingController();
  final _investigationsController = TextEditingController();
  final _treatmentsController = TextEditingController();
  final _advicesController = TextEditingController();
  
  DateTime? _nextVisitDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _procedureController.dispose();
    _investigationsController.dispose();
    _treatmentsController.dispose();
    _advicesController.dispose();
    super.dispose();
  }

  Future<void> _saveVisit() async {
    setState(() => _isLoading = true);

    final newVisit = Visit(
      patientId: widget.patientId,
      visitDate: DateTime.now(),
      procedure: _procedureController.text.trim(),
      investigations: _investigationsController.text.trim(),
      treatments: _treatmentsController.text.trim(),
      advices: _advicesController.text.trim(),
      nextVisitDate: _nextVisitDate,
    );

    try {
      await DatabaseHelper.instance.createVisit(newVisit);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // العودة للشاشة السابقة وتحديثها
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving visit: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('New Visit', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveVisit,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Clinical Details', Icons.medical_services_outlined),
                  const SizedBox(height: 15),
                  _buildTextField('Procedure / Intervention', _procedureController, maxLines: 3),
                  _buildTextField('Investigations & Labs', _investigationsController, maxLines: 3),
                  _buildTextField('Treatments & Medications', _treatmentsController, maxLines: 4),
                  _buildTextField('Medical Advices', _advicesController, maxLines: 3),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle('Follow Up', Icons.calendar_month_outlined),
                  const SizedBox(height: 15),
                  _buildNextVisitPicker(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1E3A8A), size: 24),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildNextVisitPicker() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _nextVisitDate ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null && picked != _nextVisitDate) {
          setState(() {
            _nextVisitDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _nextVisitDate == null 
                  ? 'Select Next Visit Date (Optional)' 
                  : 'Next Visit: ${DateFormat('yyyy-MM-dd').format(_nextVisitDate!)}',
              style: TextStyle(
                fontSize: 16,
                color: _nextVisitDate == null ? Colors.grey.shade600 : Colors.black87,
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}
