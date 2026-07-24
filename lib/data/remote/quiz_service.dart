import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';
import '../models/test_mark_model.dart';

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _quizzes => _db.collection('quizzes');
  CollectionReference get _marks => _db.collection('test_marks');

  /// Create a new test/quiz
  Future<void> createQuiz(QuizModel quiz) async {
    await _quizzes.doc(quiz.id).set(quiz.toMap());
  }

  /// Get tests for a specific class (Safe query)
  Stream<List<QuizModel>> watchQuizzesByClass(
      String classId, String academyId) {
    return _quizzes
        .where('academy_id', isEqualTo: academyId)
        .where('class_id', isEqualTo: classId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) =>
              QuizModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(2000);
        final dateB = b.createdAt ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// Delete a test and all its marks atomically (a single batch per chunk,
  /// so a mid-delete failure can't leave the quiz gone with orphaned marks
  /// still referencing it, or vice versa).
  Future<void> deleteQuiz(String quizId, String academyId) async {
    final marks = await _marks
        .where('academy_id', isEqualTo: academyId)
        .where('quiz_id', isEqualTo: quizId)
        .get();

    // Firestore batches cap at 500 ops; chunk conservatively and always
    // include the quiz-doc delete in the first chunk.
    const chunkSize = 450;
    var batch = _db.batch();
    batch.delete(_quizzes.doc(quizId));
    var opsInBatch = 1;

    for (final doc in marks.docs) {
      if (opsInBatch >= chunkSize) {
        await batch.commit();
        batch = _db.batch();
        opsInBatch = 0;
      }
      batch.delete(doc.reference);
      opsInBatch++;
    }
    await batch.commit();
  }

  /// Bulk upload marks for a class
  Future<void> uploadBulkMarks(List<TestMarkModel> marksList) async {
    final batch = _db.batch();
    for (var mark in marksList) {
      final docRef = _marks.doc("${mark.quizId}_${mark.studentId}");
      batch.set(docRef, mark.toMap());
    }
    await batch.commit();
  }

  /// Watch marks for a specific quiz (Safe query)
  Stream<List<TestMarkModel>> watchMarksByQuiz(
      String quizId, String academyId) {
    return _marks
        .where('academy_id', isEqualTo: academyId)
        .where('quiz_id', isEqualTo: quizId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TestMarkModel.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Watch marks for a specific student (Safe query)
  Stream<List<TestMarkModel>> watchStudentMarks(
      String studentUid, String academyId) {
    return _marks
        .where('academy_id', isEqualTo: academyId)
        .where('student_id', isEqualTo: studentUid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) =>
              TestMarkModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) {
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return list;
    });
  }

  /// Get all marks for a class (Safe query)
  Stream<List<TestMarkModel>> watchClassMarks(
      String classId, String academyId) {
    return _marks
        .where('academy_id', isEqualTo: academyId)
        .where('class_id', isEqualTo: classId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TestMarkModel.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// NEW: Fetch ALL marks across the academy (for AI Predictions)
  Future<List<TestMarkModel>> getAllAcademyMarks(String academyId) async {
    final snap = await _marks.where('academy_id', isEqualTo: academyId).get();
    return snap.docs
        .map((doc) =>
            TestMarkModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }
}
