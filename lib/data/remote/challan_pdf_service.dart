import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/fee_challan_model.dart';

class ChallanPdfService {
  static Future<void> generateAndPrint(FeeChallanModel challan) async {
    try {
      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildHeader(challan),
                pw.SizedBox(height: 20),
                _buildStudentInfo(challan),
                pw.SizedBox(height: 20),
                _buildFeeTable(challan),
                pw.SizedBox(height: 20),
                _buildFooter(challan),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'Challan_${challan.challanNumber}',
      );
    } catch (e) {
      throw Exception("PDF Generation failed: $e");
    }
  }

  static pw.Widget _buildHeader(FeeChallanModel challan) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("TALEEMPLUS ACADEMY", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.Text("123 Education Lane, Learning City", style: const pw.TextStyle(fontSize: 10)),
            pw.Text("Contact: +92 301 4334151", style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text("FEE CHALLAN", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.cyan)),
            pw.Text("No: ${challan.challanNumber}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text("Date: ${DateFormat('dd-MMM-yyyy').format(challan.issueDate)}"),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildStudentInfo(FeeChallanModel challan) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow("Student Name", challan.studentName),
                _infoRow("Father Name", challan.fatherName),
                _infoRow("Student ID", challan.studentId),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow("Class", challan.classLabel),
                _infoRow("Roll No", challan.rollNumber),
                _infoRow("Due Date", DateFormat('dd-MMM-yyyy').format(challan.dueDate)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: "$label: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildFeeTable(FeeChallanModel challan) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Description", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Amount (PKR)", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          ],
        ),
        _tableRow("Monthly Tuition Fee", challan.monthlyFee),
        _tableRow("Admission Fee", challan.admissionFee),
        _tableRow("Examination Fee", challan.examFee),
        _tableRow("Transport Charges", challan.transportFee),
        _tableRow("Fine / Arrears", challan.fine),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey50),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Total Payable", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Rs. ${challan.totalAmount.toStringAsFixed(0)}", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _tableRow(String desc, double amount) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(desc, style: const pw.TextStyle(fontSize: 10))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(amount.toStringAsFixed(0), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
      ],
    );
  }

  static pw.Widget _buildFooter(FeeChallanModel challan) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("PAYMENT INSTRUCTIONS:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text("Account Title: Academy Management", style: const pw.TextStyle(fontSize: 9)),
            pw.Text("Account Number: 03014334151", style: const pw.TextStyle(fontSize: 9)),
            pw.Text("Please share the screenshot of payment on WhatsApp.", style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: "Challan:${challan.challanNumber}|Student:${challan.studentId}|Amount:${challan.totalAmount}",
          width: 60,
          height: 60,
        ),
      ],
    );
  }
}
