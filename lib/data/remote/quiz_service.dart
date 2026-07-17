import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';
import '../models/test_mark_model.dart';

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _quizzes => _db.collection('quizzes');
  CollectionReference get _marks => _db.collection('test_marks');

  // --- Teacher Operations ---

  /// Create a new test/quiz
  Future<void> createQuiz(QuizModel quiz) async {
    await _quizzes.doc(quiz.id).set(quiz.toMap());
  }

  /// Get tests for a specific class
  Stream<List<QuizModel>> watchQuizzesByClass(String classId) {
    return _quizzes
        .where('class_id', isEqualTo: classId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => QuizModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Delete a test
  Future<void> deleteQuiz(String quizId) async {
    await _quizzes.doc(quizId).delete();
    // Also delete all associated marks
    final marks = await _marks.where('quiz_id', isEqualTo: quizId).get();
    for (var doc in marks.docs) {
      await doc.reference.delete();
    }
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

  /// Watch marks for a specific quiz (for Teacher/Admin review)
  Stream<List<TestMarkModel>> watchMarksByQuiz(String quizId) {
    return _marks
        .where('quiz_id', isEqualTo: quizId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TestMarkModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // --- Student/Parent/Admin Operations ---

  /// Watch marks for a specific student (for Report Screen)
  Stream<List<TestMarkModel>> watchStudentMarks(String studentUid) {
    return _marks
        .where('student_id', isEqualTo: studentUid)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TestMarkModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get all marks for a class (for Admin Analytics)
  Stream<List<TestMarkModel>> watchClassMarks(String classId) {
    return _marks
        .where('class_id', isEqualTo: classId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TestMarkModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }
}
