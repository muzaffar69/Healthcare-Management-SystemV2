import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/prescription_model.dart';
import '../../data/models/lab_order_model.dart';
import '../../data/models/doctor_settings_model.dart';

class PdfGenerator {
  /// Generates a prescription PDF and returns the file path
  static Future<String> generatePrescription({
    required Patient patient,
    required List<Prescription> prescriptions,
    required String visitDate,
    required String visitDetails,
    required DoctorSettings doctorSettings,
  }) async {
    final pdf = pw.Document();

    // Add page to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(doctorSettings),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildPrescriptionTitle(),
          _buildPatientInfo(patient),
          _buildVisitInfo(visitDate, visitDetails),
          _buildPrescriptionsList(prescriptions),
          _buildDoctorSignature(doctorSettings),
        ],
      ),
    );

    // Save the PDF
    return await _savePdf(pdf, 'prescription_${patient.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
  }

  /// Generates a lab order PDF and returns the file path
  static Future<String> generateLabOrder({
    required Patient patient,
    required List<LabOrder> labOrders,
    required String visitDate,
    required String visitDetails,
    required DoctorSettings doctorSettings,
  }) async {
    final pdf = pw.Document();

    // Add page to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(doctorSettings),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildLabOrderTitle(),
          _buildPatientInfo(patient),
          _buildVisitInfo(visitDate, visitDetails),
          _buildLabOrdersList(labOrders),
          _buildDoctorSignature(doctorSettings),
        ],
      ),
    );

    // Save the PDF
    return await _savePdf(pdf, 'lab_order_${patient.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
  }

  // Helper methods for building PDF components

  static pw.Widget _buildHeader(DoctorSettings doctorSettings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  doctorSettings.name ?? 'Doctor Name',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  doctorSettings.specialty ?? '',
                  style: const pw.TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            pw.Container(
              height: 50,
              width: 50,
              decoration: const pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: PdfColors.grey300,
              ),
              child: pw.Center(
                child: pw.Text(
                  'Logo',
                  style: const pw.TextStyle(
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Icon(
              const pw.IconData(0xe3ab), // Phone icon
              size: 14,
            ),
            pw.SizedBox(width: 5),
            pw.Text(doctorSettings.phoneNumber ?? ''),
            pw.SizedBox(width: 20),
            pw.Icon(
              const pw.IconData(0xe0be), // Email icon
              size: 14,
            ),
            pw.SizedBox(width: 5),
            pw.Text(doctorSettings.email ?? ''),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Icon(
              const pw.IconData(0xe3ab), // Location icon
              size: 14,
            ),
            pw.SizedBox(width: 5),
            pw.Text(doctorSettings.address ?? ''),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPrescriptionTitle() {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Text(
        'PRESCRIPTION',
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
    );
  }

  static pw.Widget _buildLabOrderTitle() {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Text(
        'LABORATORY TEST ORDER',
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
    );
  }

  static pw.Widget _buildPatientInfo(Patient patient) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PATIENT INFORMATION',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Name:', patient.name),
                    _buildInfoRow('Age:', '${patient.age} years'),
                    _buildInfoRow('Gender:', patient.gender),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Phone:', patient.phoneNumber),
                    _buildInfoRow('Address:', patient.address ?? 'N/A'),
                    if (patient.chronicDiseases != null && patient.chronicDiseases!.isNotEmpty)
                      _buildInfoRow('Chronic Diseases:', patient.chronicDiseases!),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildVisitInfo(String visitDate, String visitDetails) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VISIT INFORMATION',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Visit Date:', visitDate),
          pw.SizedBox(height: 5),
          pw.Text(
            'Details:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(visitDetails),
        ],
      ),
    );
  }

  static pw.Widget _buildPrescriptionsList(List<Prescription> prescriptions) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Icon(
                const pw.IconData(0xe3a9), // Medicine icon
                color: PdfColors.blue800,
                size: 20,
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                'PRESCRIBED MEDICATIONS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          if (prescriptions.isEmpty)
            pw.Text('No medications prescribed.'),
          ...List.generate(prescriptions.length, (index) {
            final prescription = prescriptions[index];
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${index + 1}. ${prescription.drugName}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Instructions: ${prescription.note}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildLabOrdersList(List<LabOrder> labOrders) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Icon(
                const pw.IconData(0xe3a9), // Lab icon
                color: PdfColors.blue800,
                size: 20,
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                'LABORATORY TESTS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          if (labOrders.isEmpty)
            pw.Text('No laboratory tests ordered.'),
          ...List.generate(labOrders.length, (index) {
            final labOrder = labOrders[index];
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${index + 1}. ${labOrder.testName}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Notes: ${labOrder.note}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildDoctorSignature(DoctorSettings doctorSettings) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            width: 200,
            height: 50,
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Doctor\'s Signature',
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Container(
            width: 200,
            alignment: pw.Alignment.center,
            child: pw.Text(
              doctorSettings.name ?? 'Doctor Name',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          if (doctorSettings.specialty != null)
            pw.Container(
              width: 200,
              alignment: pw.Alignment.center,
              child: pw.Text(
                doctorSettings.specialty!,
                style: const pw.TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Future<String> _savePdf(pw.Document pdf, String fileName) async {
    // Get temporary directory
    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/$fileName';
    final file = File(filePath);
    
    // Save the PDF file
    await file.writeAsBytes(await pdf.save());
    
    return filePath;
  }

  // Opens the generated PDF file
  static Future<void> openPdf(String filePath) async {
    await OpenFile.open(filePath);
  }
}