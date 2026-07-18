import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/quiz_model.dart';

class PdfGeneratorService {
  /// Print preview kholta hai (system print dialog — wahan se
  /// "Save as PDF" printer chun kar bhi save kar sakte hain)
  static Future<void> printTestPaper(QuizModel quiz) async {
    final pdf = _buildDocument(quiz);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${quiz.title}_Paper',
    );
  }

  /// Share sheet kholta hai — PDF ko Files mein save karein,
  /// WhatsApp/Email pe bhejein, waghera. (Mobile pe "download" yehi hai)
  static Future<void> shareTestPaper(QuizModel quiz) async {
    final pdf = _buildDocument(quiz);
    final bytes = await pdf.save();
    final safeName =
    quiz.title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    await Printing.sharePdf(bytes: bytes, filename: '$safeName.pdf');
  }

  /// PDF document banata hai (dono methods yehi use karte hain)
  static pw.Document _buildDocument(QuizModel quiz) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Section
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(quiz.classLabel.toUpperCase(),
                      style: const pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(quiz.title,
                      style: const pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text("Subject: ${quiz.subject}",
                      style: const pw.TextStyle(fontSize: 14)),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            // Student Info Section (Blank for physical test)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Month: ${quiz.month}"),
                pw.Text("Session: ${quiz.session}"),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Chapter: ${quiz.chapter}"),
                pw.Text("Difficulty: ${quiz.difficulty}"),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Student Name: __________________________"),
                pw.Text("Roll No: __________"),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Date: ________________"),
                pw.Text("Total Marks: ${quiz.totalMarks}",
                    style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 20),

            // Instructions
            if (quiz.instructions.isNotEmpty) ...[
              pw.Text("Instructions:",
                  style: const pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text(quiz.instructions,
                  style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 20),
            ],

            // Questions Section
            ...quiz.questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Q${i + 1}. ",
                            style:
                            const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Expanded(
                          child: pw.Text(q.text,
                              style: const pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Text("(${q.marks} Marks)",
                            style: const pw.TextStyle(
                                fontStyle: pw.FontStyle.italic,
                                fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    if (q.type == QuestionType.mcq && q.options != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 20),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: q.options!.asMap().entries.map((optEntry) {
                            final optLetter =
                            String.fromCharCode(65 + optEntry.key);
                            return pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              child:
                              pw.Text("$optLetter) ${optEntry.value}"),
                            );
                          }).toList(),
                        ),
                      )
                    else
                      pw.Padding(
                        padding:
                        const pw.EdgeInsets.only(top: 8, bottom: 20),
                        child: pw.Container(
                          height: 60,
                          width: double.infinity,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),

            pw.Footer(
              margin: const pw.EdgeInsets.only(top: 20),
              trailing: pw.Text("Generated by TaleemPlus AI",
                  style:
                  const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            ),
          ];
        },
      ),
    );

    return pdf;
  }
}