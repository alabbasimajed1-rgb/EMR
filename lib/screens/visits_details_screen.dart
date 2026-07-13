import 'package:flutter/material.dart';
import 'dart:io';
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
  bool _isLoadingImages = true;
  List<String> _imagePaths = [];

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
    
    _loadImages();
  }

  Future<void> _loadImages() async {
    if (widget.visit.id != null) {
      try {
        final paths = await DatabaseHelper.instance.getImagesForVisit(widget.visit.id!);
        if (mounted) {
          setState(() {
            _imagePaths = paths;
            _isLoadingImages = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingImages = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingImages = false);
    }
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

  void _showFullImage(File file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    if (_isLoadingImages) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0, top: 8.0),
          child: Text(
            'Attached Documents',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imagePaths.length,
            itemBuilder: (context, index) {
              final file = File(_imagePaths[index]);
              return GestureDetector(
                onTap: () => _showFullImage(file),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    image: DecorationImage(
                      image: FileImage(file),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('Procedure / Intervention', _procedureController),
            _buildField('Investigations & Labs', _investigationsController),
            _buildImageGallery(), // معرض الصور يظهر هنا مباشرة تحت الفحوصات
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
