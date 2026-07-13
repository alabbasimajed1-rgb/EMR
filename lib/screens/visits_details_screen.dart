import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../services/database_helper.dart';

class VisitDetailsScreen extends StatefulWidget {
  final Visit visit;

  const VisitDetailsScreen({super.key, required this.visit});

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  bool _isEditing = false;

  late TextEditingController _procedureController;
  late TextEditingController _investigationsController;
  late TextEditingController _treatmentsController;
  late TextEditingController _advicesController;

  @override
  void initState() {
    super.initState();
    _procedureController = TextEditingController(text: widget.visit.procedure);
    _investigationsController = TextEditingController(text: widget.visit.investigations);
    _treatmentsController = TextEditingController(text: widget.visit.treatments);
    _advicesController = TextEditingController(text: widget.visit.advices);
  }

  @override
  void dispose() {
    _procedureController.dispose();
    _investigationsController.dispose();
    _treatmentsController.dispose();
    _advicesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    Visit updatedVisit = Visit(
      id: widget.visit.id,
      patientId: widget.visit.patientId,
      visitDate: widget.visit.visitDate,
      procedure: _procedureController.text.trim(),
      investigations: _investigationsController.text.trim(),
      treatments: _treatmentsController.text.trim(),
      advices: _advicesController.text.trim(),
      nextVisitDate: widget.visit.nextVisitDate,
    );

    try {
      await DatabaseHelper.instance.updateVisit(updatedVisit);
      
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating visit: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Visit Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save_rounded : Icons.edit_rounded),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildField('Procedure / Intervention', _procedureController),
            _buildField('Investigations & Labs', _investigationsController),
            _buildField('Treatments & Medications', _treatmentsController),
            _buildField('Medical Advices', _advicesController),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _isEditing ? const Color(0xFF1E3A8A) : Colors.grey.shade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: !_isEditing,
          fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
          ),
        ),
      ),
    );
  }
}
