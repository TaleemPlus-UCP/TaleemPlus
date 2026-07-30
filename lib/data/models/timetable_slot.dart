import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A single recurring weekly period in a class's schedule — e.g. "Class 9-B
/// has Physics with Teacher X every Monday 8:00-8:45 in Room 101, Fall 2026."
/// `classId`/`className`/`section`/`subject`/`teacherId`/`teacherName` are all
/// empty when [isBreak] is true (a break has no class or teacher attached).
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

  Map<String, dynamic> toMap() {
    return {
      'academy_id': academyId,
      'is_break': isBreak,
      'class_id': classId,
      'class_name': className,
      'section': section,
      'subject': subject,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'day_of_week': dayOfWeek,
      'start_minutes': startMinutes,
      'end_minutes': endMinutes,
      'room': room,
      'semester': semester,
      'effective_from': Timestamp.fromDate(effectiveFrom),
      'effective_to':
          effectiveTo != null ? Timestamp.fromDate(effectiveTo!) : null,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  factory TimetableSlot.fromMap(String id, Map<String, dynamic> map) {
    final effectiveFrom = map['effective_from'];
    final effectiveTo = map['effective_to'];
    final createdAt = map['created_at'];
    final updatedAt = map['updated_at'];
    return TimetableSlot(
      id: id,
      academyId: map['academy_id'] ?? '',
      isBreak: map['is_break'] ?? false,
      classId: map['class_id'] ?? '',
      className: map['class_name'] ?? '',
      section: map['section'] ?? '',
      subject: map['subject'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      teacherName: map['teacher_name'] ?? '',
      dayOfWeek: (map['day_of_week'] ?? DateTime.monday) as int,
      startMinutes: (map['start_minutes'] ?? 0) as int,
      endMinutes: (map['end_minutes'] ?? 0) as int,
      room: map['room'] ?? '',
      semester: map['semester'] ?? '',
      effectiveFrom:
          effectiveFrom is Timestamp ? effectiveFrom.toDate() : DateTime.now(),
      effectiveTo: effectiveTo is Timestamp ? effectiveTo.toDate() : null,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }
}
