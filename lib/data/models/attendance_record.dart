/// One day's attendance status for a student, as returned by the
/// `/attendance/students/{id}/monthly` endpoint.
class AttendanceDayRecord {
  final DateTime logDate;
  final String status; // 'present' | 'absent' | 'late'
  final DateTime? recordedAt;

  const AttendanceDayRecord({
    required this.logDate,
    required this.status,
    this.recordedAt,
  });

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isLate => status == 'late';

  factory AttendanceDayRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceDayRecord(
      logDate: DateTime.parse(json['logDate'] as String),
      status: (json['status'] as String).toLowerCase(),
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'] as String)
          : null,
    );
  }
}

/// Present/absent/late counts + percentage over a date range.
class AttendanceSummary {
  final int totalDays;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final double percentage;

  const AttendanceSummary({
    required this.totalDays,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.percentage,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalDays: json['totalDays'] as int,
      presentCount: json['presentCount'] as int,
      absentCount: json['absentCount'] as int,
      lateCount: json['lateCount'] as int,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

/// One student's daily records + summary for a single month.
class AttendanceMonthlyReport {
  final int year;
  final int month;
  final List<AttendanceDayRecord> records;
  final AttendanceSummary summary;

  const AttendanceMonthlyReport({
    required this.year,
    required this.month,
    required this.records,
    required this.summary,
  });

  factory AttendanceMonthlyReport.fromJson(Map<String, dynamic> json) {
    final records = json['records'] as List<dynamic>;
    return AttendanceMonthlyReport(
      year: json['year'] as int,
      month: json['month'] as int,
      records: records
          .map((r) => AttendanceDayRecord.fromJson(r as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.logDate.compareTo(b.logDate)),
      summary: AttendanceSummary.fromJson(json),
    );
  }
}

/// One month's summary within a yearly report.
class AttendanceMonthSummary {
  final int month;
  final AttendanceSummary summary;

  const AttendanceMonthSummary({required this.month, required this.summary});

  factory AttendanceMonthSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceMonthSummary(
      month: json['month'] as int,
      summary: AttendanceSummary.fromJson(json),
    );
  }
}

/// One student's month-by-month summary for a whole year.
class AttendanceYearlyReport {
  final int year;
  final List<AttendanceMonthSummary> months;

  const AttendanceYearlyReport({required this.year, required this.months});

  factory AttendanceYearlyReport.fromJson(Map<String, dynamic> json) {
    final months = json['months'] as List<dynamic>;
    return AttendanceYearlyReport(
      year: json['year'] as int,
      months: months
          .map(
              (m) => AttendanceMonthSummary.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
