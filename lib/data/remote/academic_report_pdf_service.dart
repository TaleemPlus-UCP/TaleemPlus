import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/app_user.dart';
import '../models/attendance_record.dart';
import '../models/class_entity.dart';
import '../models/test_mark_model.dart';

class AcademicReportPdfService {
  static Future<void> attendance({
    required AppUser student,
    required List<AttendanceRecord> records,
    required List<ClassEntity> classes,
  }) async {
    final sorted = [...records]..sort((a, b) => a.logDate.compareTo(b.logDate));
    final present = sorted.where((r) => r.status == 'present').length;
    final absent = sorted.where((r) => r.status == 'absent').length;
    final late = sorted.where((r) => r.status == 'late').length;
    final percent =
        sorted.isEmpty ? 0.0 : (present + late) * 100 / sorted.length;
    final classById = {for (final c in classes) c.id: c};
    final logo = await _loadLogo(student.academyLogo);
    final from = sorted.isEmpty ? null : sorted.first.logDate;
    final to = sorted.isEmpty ? null : sorted.last.logDate;
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 42),
      header: (_) => _header(student, 'ATTENDANCE REPORT', logo),
      footer: (context) => _footer(context),
      build: (_) => [
        _studentDetails(student, [
          'Class: ${classes.map((c) => c.displayLabel).toSet().join(', ')}',
          'Date range: ${from == null ? '—' : DateFormat('d MMM yyyy').format(from)} – ${to == null ? '—' : DateFormat('d MMM yyyy').format(to)}',
        ]),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(children: [
              _summaryCell('Present', '$present', PdfColors.green800),
              _summaryCell('Absent', '$absent', PdfColors.red800),
              _summaryCell('Late', '$late', PdfColors.orange800),
              _summaryCell('Attendance', '${percent.toStringAsFixed(1)}%',
                  PdfColors.blue800),
            ])
          ],
        ),
        pw.SizedBox(height: 18),
        _table(
            ['Date', 'Class / Subject', 'Status'],
            sorted
                .map((r) => [
                      DateFormat('d MMM yyyy').format(r.logDate),
                      classById[r.classId]?.displayLabel ?? 'Class',
                      r.status.toUpperCase(),
                    ])
                .toList()),
        pw.SizedBox(height: 38),
        _signatures(),
      ],
    ));
    await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
        name: 'Attendance_${student.studentCode}.pdf');
  }

  static Future<void> results({
    required AppUser student,
    required List<TestMarkModel> marks,
  }) async {
    final sorted = [...marks]
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    final obtained = sorted.fold<double>(0, (sum, m) => sum + m.marksObtained);
    final possible = sorted.fold<double>(0, (sum, m) => sum + m.totalMarks);
    final percent = possible == 0 ? 0.0 : obtained * 100 / possible;
    final logo = await _loadLogo(student.academyLogo);
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 42),
      header: (_) => _header(student, 'ACADEMIC RESULT', logo),
      footer: (context) => _footer(context),
      build: (_) => [
        _studentDetails(student, [
          'Examination records: ${sorted.length}',
          'Academic session: ${sorted.map((m) => m.month).where((m) => m.isNotEmpty).toSet().join(', ')}'
        ]),
        pw.SizedBox(height: 16),
        pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(children: [
                _summaryCell('Marks obtained', obtained.toStringAsFixed(1),
                    PdfColors.blue800),
                _summaryCell('Total marks', possible.toStringAsFixed(1),
                    PdfColors.blue800),
                _summaryCell('Percentage', '${percent.toStringAsFixed(1)}%',
                    PdfColors.green800),
                _summaryCell('Overall grade',
                    TestMarkModel.calculateGrade(percent), PdfColors.indigo800),
              ])
            ]),
        pw.SizedBox(height: 18),
        _table(
            ['Subject', 'Assessment', 'Marks', 'Grade', 'Date'],
            sorted
                .map((m) => [
                      m.subject,
                      m.month.isEmpty ? 'Assessment' : m.month,
                      '${m.marksObtained.toStringAsFixed(1)} / ${m.totalMarks.toStringAsFixed(1)}',
                      m.gradeLetter,
                      DateFormat('d MMM yyyy').format(m.updatedAt),
                    ])
                .toList()),
        if (sorted.any((m) => (m.teacherFeedback ?? '').trim().isNotEmpty)) ...[
          pw.SizedBox(height: 18),
          pw.Text('Teacher remarks',
              style: const pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900)),
          ...sorted
              .where((m) => (m.teacherFeedback ?? '').trim().isNotEmpty)
              .map((m) => pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 5),
                    child: pw.Text('${m.subject}: ${m.teacherFeedback}'),
                  )),
        ],
        pw.SizedBox(height: 38),
        _signatures(),
      ],
    ));
    await Printing.layoutPdf(
        onLayout: (_) => pdf.save(), name: 'Result_${student.studentCode}.pdf');
  }

  static Future<pw.ImageProvider?> _loadLogo(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      return await networkImage(url);
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _header(
          AppUser student, String title, pw.ImageProvider? logo) =>
      pw.Column(children: [
        if (logo != null)
          pw.Container(width: 48, height: 48, child: pw.Image(logo)),
        pw.Text((student.academyName ?? 'TaleemPlus Academy').toUpperCase(),
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
                fontSize: 17,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900)),
        if ((student.academyAddress ?? '').isNotEmpty)
          pw.Text(student.academyAddress!,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9)),
        if ((student.academyPhone ?? '').isNotEmpty)
          pw.Text(student.academyPhone!,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9)),
        pw.Divider(color: PdfColors.blueGrey700),
        pw.SizedBox(height: 5),
        pw.Text(title,
            style: const pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.2)),
        pw.SizedBox(height: 14),
      ]);

  static pw.Widget _studentDetails(AppUser student, List<String> details) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(11),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Student: ${student.fullName}',
                  style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  'Student ID: ${student.studentCode.isEmpty ? student.uid : student.studentCode}'),
              ...details.map((d) => pw.Text(d)),
            ]),
      );

  static pw.Widget _summaryCell(String label, String value, PdfColor color) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Column(children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 3),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold, color: color))
        ]),
      );

  static pw.Widget _table(List<String> headers, List<List<String>> rows) =>
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
        headerStyle: const pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
      );

  static pw.Widget _signatures() => pw.Row(children: [
        pw.Expanded(
            child: pw.Column(children: [
          pw.SizedBox(height: 22),
          pw.Container(height: .7, color: PdfColors.grey700),
          pw.SizedBox(height: 5),
          pw.Text('Class teacher', style: const pw.TextStyle(fontSize: 9))
        ])),
        pw.SizedBox(width: 35),
        pw.Expanded(
            child: pw.Column(children: [
          pw.SizedBox(height: 22),
          pw.Container(height: .7, color: PdfColors.grey700),
          pw.SizedBox(height: 5),
          pw.Text('Principal / stamp', style: const pw.TextStyle(fontSize: 9))
        ])),
      ]);

  static pw.Widget _footer(pw.Context context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated from TaleemPlus academy records',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8))
        ],
      );
}
