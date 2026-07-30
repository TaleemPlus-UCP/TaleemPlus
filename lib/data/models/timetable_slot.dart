import 'package:flutter/material.dart';

/// A single recurring weekly period in a class's schedule — e.g. "Class 9-B
/// has Physics with Teacher X every Monday 8:00-8:45 in Room 101, Fall 2026."
/// `classId`/`className`/`section`/`subject`/`teacherId`/`teacherName` are all
/// empty when [isBreak] is true (a break has no class or teacher attached).
///
/// `classId` here is the subject *offering* id (`ClassEntity.id`) — the
/// backend calls it `offeringId`.
class TimetableSlot {
  final String id;
  final String academyId;
  final bool isBreak;
  final String classId;
  final String className;
  final String section;
  final String subject;
  final String teacherId;
  final String teacherName;
  final int dayOfWeek; // DateTime.monday (1) .. DateTime.sunday (7)
  final int startMinutes; // minutes since midnight
  final int endMinutes;
  final String room;
  final String semester;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo; // null = ongoing, no end date
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TimetableSlot({
    required this.id,
    required this.academyId,
    this.isBreak = false,
    this.classId = '',
    this.className = '',
    this.section = '',
    this.subject = '',
    this.teacherId = '',
    this.teacherName = '',
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.room = '',
    this.semester = '',
    required this.effectiveFrom,
    this.effectiveTo,
    this.createdAt,
    this.updatedAt,
  });

  static const List<String> weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get dayName =>
      (dayOfWeek >= 1 && dayOfWeek <= 7) ? weekdayNames[dayOfWeek - 1] : '';

  static String formatMinutes(int minutes) {
    final tod = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final m = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String get timeRangeLabel =>
      '${formatMinutes(startMinutes)} - ${formatMinutes(endMinutes)}';

  String get displayLabel => isBreak
      ? 'Break'
      : '$className${section.isNotEmpty ? '-$section' : ''}'
          '${subject.isNotEmpty ? ' ($subject)' : ''}';

  /// Request body for `POST /timetable` and `PATCH /timetable/:id`.
  Map<String, dynamic> toJson() {
    return {
      'isBreak': isBreak,
      if (!isBreak) 'offeringId': classId,
      'dayOfWeek': dayOfWeek,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'room': room,
      'semester': semester,
      'effectiveFrom': _dateOnly(effectiveFrom),
      'effectiveTo': effectiveTo != null ? _dateOnly(effectiveTo!) : null,
    };
  }

  factory TimetableSlot.fromJson(Map<String, dynamic> json) {
    final offering = json['offering'] as Map<String, dynamic>?;
    final section = offering?['section'] as Map<String, dynamic>?;
    final teacher = offering?['teacher'] as Map<String, dynamic>?;
    return TimetableSlot(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      isBreak: json['isBreak'] as bool,
      classId: (offering?['id'] as String?) ?? '',
      className: (section?['className'] as String?) ?? '',
      section: (section?['sectionLabel'] as String?) ?? '',
      subject: (offering?['subject'] as String?) ?? '',
      teacherId: (teacher?['id'] as String?) ?? '',
      teacherName: (teacher?['fullName'] as String?) ?? '',
      dayOfWeek: json['dayOfWeek'] as int,
      startMinutes: json['startMinutes'] as int,
      endMinutes: json['endMinutes'] as int,
      room: (json['room'] as String?) ?? '',
      semester: (json['semester'] as String?) ?? '',
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      effectiveTo: json['effectiveTo'] != null
          ? DateTime.tryParse(json['effectiveTo'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  static String _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);
}
