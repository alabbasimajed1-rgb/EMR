import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visit.dart';
import '../models/patient.dart';
import '../services/database_helper.dart'; 
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // <--- استيراد الترجمة

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _dateRange;
  Patient? _selectedPatient;
  bool _isGenerating = false;

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue.shade700, onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _generatePdf(BuildContext context) async {
    setState(() => _isGenerating = true);

    try {
      final db = await DatabaseHelper.instance.database;
      List<Map<String, dynamic>> visitMaps;

      if (_selectedPatient != null) {
        visitMaps = await db.query('visits', where: 'patientId = ?', whereArgs: [_selectedPatient!.id]);
      } else {
        visitMaps = await db.query('visits');
      }

      List<Visit> visits = visitMaps.map((map) => Visit.fromMap(map)).toList();

      if (_dateRange != null) {
        visits = visits.where((v) {
          return v.visitDate.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
                 v.visitDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        }).toList();
      }

      if (visits.isEmpty && _selectedPatient == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No records found for the selected criteria.')));
        }
        setState(() => _isGenerating = false);
        return;
      }

      visits.sort((a, b) => b.visitDate.compareTo(a.visitDate));

      final prefs = await SharedPreferences.getInstance();
      final doctorName = prefs.getString('doctor_name') ?? 'Clinic Doctor';
      final specialty = prefs.getString('doctor_specialty') ?? 'Medical Specialty';
      // تحديد اللغة الحالية للتطبيق لتوجيه الـ PDF
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';

      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicFontBold = await PdfGoogleFonts.cairoBold();

      final pdf = pw.Document(theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold));
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          // تحديد اتجاه الصفحة بالكامل (مهم جداً للعربي)
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          footer: (pw.Context context) {
            return pw.Container(
              alignment: isArabic ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 20.0),
              child: pw.Column(
                crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(doctorName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.black)),
                  pw.Text(specialty, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                ]
              )
            );
          },
          build: (ctx) => [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    _selectedPatient != null ? (isArabic ? 'التقرير الطبي للمريض' : 'PATIENT MEDICAL REPORT') : (isArabic ? 'تقرير الزيارات السريرية' : 'CLINICAL VISITS REPORT'), 
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(isArabic ? 'إلى من يهمه الأمر،' : 'To whom it may concern,', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800)),
                  pw.SizedBox(height: 24),
                ],
              ),
            ),
            
            if (_selectedPatient != null) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100, border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${isArabic ? 'اسم المريض:' : 'Patient Name:'} ${_selectedPatient!.fullName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('${isArabic ? 'العمر:' : 'Age:'} ${_selectedPatient!.age}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    // لاحظ كيف نعالج الجنس بناء على اللغة (بما أنه محفوظ كـ Male/Female)
                    pw.Text('${isArabic ? 'الجنس:' : 'Gender:'} ${isArabic ? (_selectedPatient!.gender == 'Male' ? 'ذكر' : 'أنثى') : _selectedPatient!.gender}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ]
                )
              ),
              pw.SizedBox(height: 20),

              pw.Text(isArabic ? 'التقييم السريري' : 'CLINICAL ASSESSMENT', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.Divider(color: PdfColors.blue800, thickness: 1),
              pw.SizedBox(height: 10),

              if (_selectedPatient!.chiefComplaint.isNotEmpty) ...[
                pw.Text(isArabic ? 'الشكوى الرئيسية:' : 'Chief Complaint:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 2),
                pw.Text(_selectedPatient!.chiefComplaint, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
                pw.SizedBox(height: 12),
              ],

              if (_selectedPatient!.medicalHistory.isNotEmpty) ...[
                pw.Text(isArabic ? 'التاريخ الطبي:' : 'Medical History (Clinical Data):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 2),
                pw.Text(_selectedPatient!.medicalHistory, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
                pw.SizedBox(height: 12),
              ],

              if (_selectedPatient!.investigationAndImaging.isNotEmpty) ...[
                pw.Text(isArabic ? 'الفحوصات والأشعة:' : 'Investigations & Imaging:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 2),
                pw.Text(_selectedPatient!.investigationAndImaging, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
                pw.SizedBox(height: 12),
              ],
              
              if (_selectedPatient!.differentialDiagnosis.isNotEmpty) ...[
                pw.Text(isArabic ? 'التشخيص التفريقي:' : 'Differential Diagnosis:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 2),
                pw.Text(_selectedPatient!.differentialDiagnosis, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
                pw.SizedBox(height: 12),
              ],

              if (_selectedPatient!.finalDiagnosis.isNotEmpty) ...[
                pw.Text(isArabic ? 'التشخيص النهائي:' : 'Final Diagnosis:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 2),
                pw.Text(_selectedPatient!.finalDiagnosis, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
                pw.SizedBox(height: 12),
              ],

              if (_selectedPatient!.firstTreatmentPlan.isNotEmpty) ...[
                pw.Text(isArabic ? 'خطة العلاج المبدئية:' : 'Initial Treatment Plan:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 2),
                pw.Text(_selectedPatient!.firstTreatmentPlan, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
                pw.SizedBox(height: 24),
              ],
            ],

            if (visits.isNotEmpty) ...[
              pw.Text(isArabic ? 'سجل الزيارات' : 'VISIT RECORDS', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.Divider(color: PdfColors.blue800, thickness: 1),
              pw.SizedBox(height: 10),
            ] else if (_selectedPatient != null) ...[
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text(isArabic ? 'لم يتم تسجيل زيارات متابعة حتى الآن.' : 'No follow-up visits recorded yet.', style: pw.TextStyle(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic))),
            ],

            if (_dateRange != null && _selectedPatient == null) ...[
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: const pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.all(pw.Radius.circular(5))),
                child: pw.Text(isArabic ? 'الفترة: ${_dateRange!.start.toString().substring(0, 10)}  إلى  ${_dateRange!.end.toString().substring(0, 10)}' : 'Period: ${_dateRange!.start.toString().substring(0, 10)}  TO  ${_dateRange!.end.toString().substring(0, 10)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
            ],
            
            ...visits.map((v) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${isArabic ? 'تاريخ الزيارة:' : 'Visit Date:'} ${v.visitDate.toString().substring(0, 10)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 5),
                      
                      pw.Text(isArabic ? 'الشكوى / الإجراء:' : 'New complaint / Procedure:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800, fontSize: 10)),
                      pw.Text(v.procedure, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.2)),
                      pw.SizedBox(height: 8),
                      
                      if (v.investigations.isNotEmpty) ...[
                        pw.Text(isArabic ? 'الفحوصات:' : 'Investigations:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800, fontSize: 10)),
                        pw.Text(v.investigations, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.2)),
                        pw.SizedBox(height: 8),
                      ],
                      
                      if (v.treatments.isNotEmpty) ...[
                        pw.Text(isArabic ? 'العلاج الموصوف:' : 'Treatments Prescribed:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800, fontSize: 10)),
                        pw.Text(v.treatments, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.2)),
                        pw.SizedBox(height: 8),
                      ],

                      if (v.advices.isNotEmpty) ...[
                        pw.Text(isArabic ? 'نصائح:' : 'Advices:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800, fontSize: 10)),
                        pw.Text(v.advices, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.2)),
                      ],
                    ],
                  ),
                )),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      String fileName = _selectedPatient != null ? 'Report_${_selectedPatient!.fullName.replaceAll(' ', '_')}.pdf' : 'Clinical_Report.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
      
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // اختصار للقاموس
    final l10n = AppLocalizations.of(context);
    // التحقق من أن القاموس ليس فارغاً (لتجنب الأخطاء إذا لم يتم تحميله بعد)
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: Text(l10n.clinicalReports), backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 80, color: Colors.blue.shade200),
                const SizedBox(height: 16),
                Text(l10n.clinicalReports, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(Localizations.localeOf(context).languageCode == 'ar' ? 'قم باختيار مريض أو فترة زمنية لتصدير تقرير PDF شامل.' : 'Select a patient or a date range (or both) to export a comprehensive PDF report.', style: TextStyle(fontSize: 15, color: Colors.grey.shade600), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                
                Card(
                  elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: FutureBuilder<List<Patient>>(
                      future: DatabaseHelper.instance.getAllPatients(),
                      builder: (context, snapshot) {
                        List<Patient> patients = snapshot.data ?? [];
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<Patient?>(
                            isExpanded: true, value: _selectedPatient,
                            hint: Row(children: [Icon(Icons.groups, color: Colors.blue.shade700), const SizedBox(width: 16), Text(Localizations.localeOf(context).languageCode == 'ar' ? 'كل المرضى (تقرير عام)' : 'All Patients (Global Report)', style: const TextStyle(fontWeight: FontWeight.bold))]),
                            items: [
                              DropdownMenuItem<Patient?>(value: null, child: Row(children: [Icon(Icons.groups, color: Colors.blue.shade700), const SizedBox(width: 16), Text(Localizations.localeOf(context).languageCode == 'ar' ? 'كل المرضى (تقرير عام)' : 'All Patients (Global)', style: const TextStyle(fontWeight: FontWeight.bold))])),
                              ...patients.map((p) => DropdownMenuItem<Patient?>(value: p, child: Row(children: [const Icon(Icons.person, color: Colors.grey), const SizedBox(width: 16), Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold))]))),
                            ],
                            onChanged: (val) => setState(() => _selectedPatient = val),
                          ),
                        );
                      }
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(Icons.calendar_month, color: Colors.blue.shade700)),
                    title: Text(_dateRange == null ? (Localizations.localeOf(context).languageCode == 'ar' ? 'اختر الفترة الزمنية' : 'Select Date Range') : (Localizations.localeOf(context).languageCode == 'ar' ? 'الفترة المحددة' : 'Selected Period'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_dateRange == null ? (Localizations.localeOf(context).languageCode == 'ar' ? 'كل الوقت' : 'All Time') : '${_dateRange!.start.toString().substring(0, 10)}  to  ${_dateRange!.end.toString().substring(0, 10)}', style: TextStyle(color: _dateRange == null ? Colors.grey : Colors.blue.shade800)),
                    trailing: _dateRange != null ? IconButton(icon: const Icon(Icons.clear, color: Colors.red), onPressed: () => setState(() => _dateRange = null)) : const Icon(Icons.edit, size: 20),
                    onTap: _selectDateRange,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : () => _generatePdf(context),
                    icon: _isGenerating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.picture_as_pdf),
                    label: Text(_isGenerating ? (Localizations.localeOf(context).languageCode == 'ar' ? 'جاري الإنشاء...' : 'Generating...') : (Localizations.localeOf(context).languageCode == 'ar' ? 'إنشاء ومشاركة التقرير' : 'Generate & Share PDF'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
