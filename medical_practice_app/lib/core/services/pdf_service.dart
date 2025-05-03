import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../models/prescription_model.dart';
import '../models/lab_test_model.dart';
import '../models/user_model.dart';

class PDFService {
  // Font assets
  late pw.Font _regularFont;
  late pw.Font _boldFont;
  late pw.Font _italicFont;
  late pw.Font _boldItalicFont;
  late pw.ImageProvider _logoImage;
  
  bool _isInitialized = false;
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      // Load fonts
      _regularFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf'));
      _boldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Bold.ttf'));
      _italicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Italic.ttf'));
      _boldItalicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-BoldItalic.ttf'));
      
      // Load logo image
      _logoImage = pw.MemoryImage(
        (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
      );
      
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize PDF service: $e');
    }
  }
  
  // =======================================
  // Generate Prescription PDF
  // =======================================
  Future<File> generatePrescriptionPDF({
    required Visit visit,
    required Patient patient,
    required User doctor,
    required List<Prescription> prescriptions,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final pdf = pw.Document();
    
    // Create a PDF theme
    final theme = pw.ThemeData.withFont(
      base: _regularFont,
      bold: _boldFont,
      italic: _italicFont,
      boldItalic: _boldItalicFont,
    );
    
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => _buildPrescriptionHeader(doctor),
        footer: (pw.Context context) => _buildFooter(context),
        build: (pw.Context context) => [
          _buildPatientInfo(patient),
          pw.SizedBox(height: 20),
          _buildVisitInfo(visit),
          pw.SizedBox(height: 20),
          _buildPrescriptionTable(prescriptions),
          pw.SizedBox(height: 40),
          _buildSignatureSection(doctor),
        ],
      ),
    );
    
    // Save PDF to a temporary file
    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/prescription_${visit.id}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  pw.Widget _buildPrescriptionHeader(User doctor) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Image(_logoImage, width: 60),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                doctor.doctorName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                doctor.specialty,
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Phone: ${doctor.phoneNumber}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Email: ${doctor.email}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Address: ${doctor.address}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildPatientInfo(Patient patient) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PATIENT INFORMATION',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Name: ${patient.name}'),
                  pw.Text('Age: ${patient.age} years'),
                  pw.Text('Gender: ${patient.gender}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Phone: ${patient.phoneNumber}'),
                  pw.Text('First Visit: ${DateFormat('dd/MM/yyyy').format(patient.firstVisitDate)}'),
                  if (patient.chronicDiseases.isNotEmpty)
                    pw.Text('Chronic: ${patient.formattedChronicDiseases}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildVisitInfo(Visit visit) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VISIT DETAILS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Visit #: ${visit.visitNumber}'),
              pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(visit.visitDate)}'),
            ],
          ),
          if (visit.notes.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text('Notes: ${visit.notes}'),
          ],
        ],
      ),
    );
  }
  
  pw.Widget _buildPrescriptionTable(List<Prescription> prescriptions) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'NO.',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'MEDICATION',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        // Data rows
        for (int i = 0; i < prescriptions.length; i++)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('${i + 1}'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      prescriptions[i].drugName,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    if (prescriptions[i].notes.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        prescriptions[i].notes,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  pw.Widget _buildSignatureSection(User doctor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 120,
              height: 50,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black),
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              doctor.doctorName,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              doctor.specialty,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
  
  // =======================================
  // Generate Lab Order PDF
  // =======================================
  Future<File> generateLabOrderPDF({
    required Visit visit,
    required Patient patient,
    required User doctor,
    required List<LabTest> labTests,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final pdf = pw.Document();
    
    // Create a PDF theme
    final theme = pw.ThemeData.withFont(
      base: _regularFont,
      bold: _boldFont,
      italic: _italicFont,
      boldItalic: _boldItalicFont,
    );
    
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => _buildLabOrderHeader(doctor),
        footer: (pw.Context context) => _buildFooter(context),
        build: (pw.Context context) => [
          _buildPatientInfo(patient),
          pw.SizedBox(height: 20),
          _buildVisitInfo(visit),
          pw.SizedBox(height: 20),
          _buildLabTestsTable(labTests),
          pw.SizedBox(height: 40),
          _buildSignatureSection(doctor),
        ],
      ),
    );
    
    // Save PDF to a temporary file
    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/lab_order_${visit.id}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  pw.Widget _buildLabOrderHeader(User doctor) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Image(_logoImage, width: 60),
          pw.Text(
            'LABORATORY TEST ORDER',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                doctor.doctorName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                doctor.specialty,
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Phone: ${doctor.phoneNumber}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Email: ${doctor.email}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildLabTestsTable(List<LabTest> labTests) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'NO.',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'TEST',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        // Data rows
        for (int i = 0; i < labTests.length; i++)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('${i + 1}'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      labTests[i].testName,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    if (labTests[i].notes.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        labTests[i].notes,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  // =======================================
  // Generate Invoice PDF
  // =======================================
  Future<File> generateInvoicePDF({
    required Visit visit,
    required Patient patient,
    required User doctor,
    required List<Prescription> prescriptions,
    required List<LabTest> labTests,
    required double consultationFee,
    required Map<String, double> additionalFees,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final pdf = pw.Document();
    
    // Create a PDF theme
    final theme = pw.ThemeData.withFont(
      base: _regularFont,
      bold: _boldFont,
      italic: _italicFont,
      boldItalic: _boldItalicFont,
    );
    
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => _buildInvoiceHeader(doctor, visit),
        footer: (pw.Context context) => _buildFooter(context),
        build: (pw.Context context) => [
          _buildPatientInfo(patient),
          pw.SizedBox(height: 20),
          _buildVisitInfo(visit),
          pw.SizedBox(height: 20),
          if (prescriptions.isNotEmpty) ...[
            _buildPrescriptionTable(prescriptions),
            pw.SizedBox(height: 20),
          ],
          if (labTests.isNotEmpty) ...[
            _buildLabTestsTable(labTests),
            pw.SizedBox(height: 20),
          ],
          _buildInvoiceDetails(consultationFee, additionalFees),
          pw.SizedBox(height: 40),
          _buildSignatureSection(doctor),
        ],
      ),
    );
    
    // Save PDF to a temporary file
    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/invoice_${visit.id}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  pw.Widget _buildInvoiceHeader(User doctor, Visit visit) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Image(_logoImage, width: 60),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Invoice #: ${visit.id.substring(0, 8)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(visit.visitDate)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                doctor.doctorName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                doctor.specialty,
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Phone: ${doctor.phoneNumber}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Email: ${doctor.email}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Address: ${doctor.address}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildInvoiceDetails(
    double consultationFee,
    Map<String, double> additionalFees,
  ) {
    // Calculate total
    double total = consultationFee;
    for (final fee in additionalFees.values) {
      total += fee;
    }
    
    return pw.Column(
      children: [
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          child: pw.Text(
            'CHARGES',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'DESCRIPTION',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'AMOUNT',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
            // Consultation fee
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Consultation Fee'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    '\$${consultationFee.toStringAsFixed(2)}',
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
            // Additional fees
            for (final entry in additionalFees.entries)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(entry.key),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      '\$${entry.value.toStringAsFixed(2)}',
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            // Total
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  // =======================================
  // Common footer for all PDFs
  // =======================================
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }
  
  // =======================================
  // PDF sharing and printing
  // =======================================
  
  // Print PDF
  Future<void> printPDF(File pdfFile) async {
    final data = await pdfFile.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) => data);
  }
  
  // Share PDF
  Future<void> sharePDF(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }
}
