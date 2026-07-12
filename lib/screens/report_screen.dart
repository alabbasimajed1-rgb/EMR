import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/visit.dart';
import '../models/patient.dart';
import '../services/database_helper.dart'; // تم استبدال FirestoreService بهذا

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _dateRange;
  Patient? _selectedPatient;
  bool _isGenerating = false;
  List<Patient> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  // جلب المرضى محلياً لتعبئة القائمة المنسدلة
  Future<void> _loadPatients() async {
    final patients = await DatabaseHelper.instance.getPatients();
    if (mounted) {
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue.shade700),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _generatePdf() async {
    setState(() => _isGenerating = true);

    try {
      // جلب كل الزيارات من قاعدة البيانات المحلية
      final allVisits = await DatabaseHelper.instance.getAllVisits();

      // الفلترة محلياً
      var visits = allVisits;

      if (_dateRange != null) {
        visits = visits.where((v) {
          return v.visitDate.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
                 v.visitDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        }).toList();
      }

      if (_selectedPatient != null) {
        visits = visits.where((v) => v.patientId == _selectedPatient!.id).toList();
      }

      if (visits.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No records found.')));
        setState(() => _isGenerating = false);
        return;
      }

      visits.sort((a, b) => b.visitDate.compareTo(a.visitDate));

      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicFontBold = await PdfGoogleFonts.cairoBold();

      final pdf = pw.Document(theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold));
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          footer: (pw.Context context) => pw.Container(alignment: pw.Alignment.centerRight, margin: const pw.EdgeInsets.only(top: 20.0), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text('Dr. Majed Abbas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)), pw.Text('Consultant Anesthesia & Intensive Care', style: const pw.TextStyle(fontSize: 11))])),
          build: (ctx) => [
            pw.Header(level: 0, child: pw.Column(children: [pw.Text(_selectedPatient != null ? 'PATIENT MEDICAL REPORT' : 'CLINICAL VISITS REPORT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800))])),
            if (_selectedPatient != null) ...[
              pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(color: PdfColors.grey100), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Patient: ${_selectedPatient!.fullName}'), pw.Text('Age: ${_selectedPatient!.age}')])),
              pw.SizedBox(height: 20),
            ],
            ...visits.map((v) => pw.Container(margin: const pw.EdgeInsets.only(bottom: 12), padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('Date: ${v.visitDate.toString().substring(0, 10)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('Procedure: ${v.procedure}')]))),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      String fileName = _selectedPatient != null ? 'Report_${_selectedPatient!.fullName.replaceAll(' ', '_')}.pdf' : 'Clinical_Report.pdf';
      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
      
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('Reports & Analytics'), backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: Colors.blue.shade200),
            const SizedBox(height: 32),
            Card(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Patient?>(
                  isExpanded: true,
                  value: _selectedPatient,
                  hint: const Padding(padding: EdgeInsets.all(16), child: Text('All Patients (Global Report)')),
                  items: [
                    const DropdownMenuItem(value: null, child: Padding(padding: EdgeInsets.all(16), child: Text('All Patients (Global)'))),
                    ..._patients.map((p) => DropdownMenuItem(value: p, child: Padding(padding: EdgeInsets.all(16), child: Text(p.fullName)))),
                  ],
                  onChanged: (val) => setState(() => _selectedPatient = val),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Date Range'),
                subtitle: Text(_dateRange == null ? 'All Time' : '${_dateRange!.start.toString().substring(0, 10)} to ${_dateRange!.end.toString().substring(0, 10)}'),
                trailing: IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _dateRange = null)),
                onTap: _selectDateRange,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generatePdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(_isGenerating ? 'Generating...' : 'Generate & Share PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
