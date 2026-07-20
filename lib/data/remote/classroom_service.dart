import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shared_resource.dart';
import '../models/student_query.dart';

class ClassroomService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Shared Resources ---
  Future<void> uploadResource(SharedResource res) async {
    await _db.collection('learning_resources').add(res.toMap());
  }

  Stream<List<SharedResource>> watchResources(String classId) {
    return _db.collection('learning_resources')
        .where('class_id', isEqualTo: classId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SharedResource.fromMap(d.id, d.data())).toList());
  }

  // --- Student Queries ---
  Future<void> postQuery(StudentQuery query) async {
    await _db.collection('student_queries').add(query.toMap());
  }

  Future<void> answerQuery(String queryId, String answer) async {
    await _db.collection('student_queries').doc(queryId).update({
      'answer': answer,
      'is_resolved': true,
      'answered_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<StudentQuery>> watchQueriesForClass(String classId) {
    return _db.collection('student_queries')
        .where('class_id', isEqualTo: classId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StudentQuery.fromMap(d.id, d.data())).toList());
  }

  Stream<List<StudentQuery>> watchQueriesForTeacher(String teacherId) {
    return _db.collection('student_queries')
        .where('teacher_id', isEqualTo: teacherId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StudentQuery.fromMap(d.id, d.data())).toList());
  }
}
