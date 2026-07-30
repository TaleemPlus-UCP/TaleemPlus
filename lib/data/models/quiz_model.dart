import 'package:intl/intl.dart';

enum QuestionType { mcq, short, long }

class QuizQuestion {
  final String id;
  final String text;
  final QuestionType type;
  final List<String>? options; // For MCQ
  final int? correctIndex; // For MCQ (Teacher reference)
  final double marks;
  final List<String> gradingKeywords; // For 100% offline AI checking

  QuizQuestion({
    this.id = '',
    required this.text,
    required this.type,
    this.options,
    this.correctIndex,
    required this.marks,
    this.gradingKeywords = const [],
  });

  /// Request body shape for `POST /quizzes` / `PATCH /quizzes/:id` — no `id`,
  /// the backend assigns one.
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': type.name.toUpperCase(),
      if (options != null) 'options': options,
      if (correctIndex != null) 'correctIndex': correctIndex,
      'marks': marks,
      'gradingKeywords': gradingKeywords,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      text: json['text'] as String,
      type: QuestionType.values.firstWhere(
        (t) => t.name == (json['type'] as String).toLowerCase(),
        orElse: () => QuestionType.short,
      ),
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      correctIndex: json['correctIndex'] as int?,
      marks: (json['marks'] as num).toDouble(),
      gradingKeywords: (json['gradingKeywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// A test/quiz for one class offering. `classId` is the offering id (the
/// backend calls it `offeringId`). `classLabel`/`month` are derived, not
/// stored — the backend has no denormalized copies of them (`classLabel`
/// comes from the offering's section, `month` from `testDate`).
class QuizModel {
  final String id;
  final String academyId;
  final String classId;
  final String className;
  final String section;
  final String title;
  final String subject;
  final String session;
  final String chapter;
  final String difficulty; // 'Easy' | 'Medium' | 'Hard'
  final double totalMarks;
  final DateTime testDate;
  final String instructions;
  final String createdByUid;
  final String createdByName;
  final DateTime? createdAt;
  final List<QuizQuestion> questions;

  QuizModel({
    required this.id,
    required this.academyId,
    required this.classId,
    this.className = '',
    this.section = '',
    required this.title,
    required this.subject,
    this.session = '',
    this.chapter = '',
    this.difficulty = 'Medium',
    required this.totalMarks,
    required this.testDate,
    this.instructions = '',
    this.createdByUid = '',
    this.createdByName = '',
    this.createdAt,
    required this.questions,
  });

  String get classLabel =>
      section.isNotEmpty ? '$className ($section)' : className;

  String get month => DateFormat('MMMM').format(testDate);

  static String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0]}${s.substring(1).toLowerCase()}';

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final offering = json['offering'] as Map<String, dynamic>;
    final section = offering['section'] as Map<String, dynamic>;
    final createdBy = json['createdBy'] as Map<String, dynamic>?;
    return QuizModel(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      classId: offering['id'] as String,
      className: section['className'] as String,
      section: section['sectionLabel'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      session: (json['session'] as String?) ?? '',
      chapter: (json['chapter'] as String?) ?? '',
      difficulty: _titleCase(json['difficulty'] as String),
      totalMarks: (json['totalMarks'] as num).toDouble(),
      testDate: DateTime.parse(json['testDate'] as String),
      instructions: (json['instructions'] as String?) ?? '',
      createdByUid: (createdBy?['id'] as String?) ?? '',
      createdByName: (createdBy?['fullName'] as String?) ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      questions: (json['questions'] as List<dynamic>)
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}
