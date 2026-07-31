import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/flag.dart';
import '../models/student.dart';

/// All reads/writes to the `flags` and `students` Firestore collections.
/// Keeping this in one place means the teacher screens (create + view own
/// history) and principal screens (view all + update status) share one
/// source of truth for the data shape.
class FlagService {
  final FirebaseFirestore _firestore;

  FlagService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _flagsRef =>
      _firestore.collection('flags');

  CollectionReference<Map<String, dynamic>> get _studentsRef =>
      _firestore.collection('students');

  /// All students, for the "Select Student" dropdown. Seed this
  /// collection manually in the Firestore console for now — there's no
  /// "add student" screen in the current designs.
  Stream<List<Student>> streamStudents({String? schoolName}) {
    Query<Map<String, dynamic>> query = _studentsRef.orderBy('fullName');
    if (schoolName != null && schoolName.isNotEmpty) {
      query = query.where('schoolName', isEqualTo: schoolName);
    }
    return query.snapshots().map(
      (snap) =>
          snap.docs.map((doc) => Student.fromMap(doc.id, doc.data())).toList(),
    );
  }

  /// Flags submitted by one teacher, newest first — powers the
  /// "Recent Submissions" list and the Flagging History screen.
  Stream<List<StudentFlag>> streamFlagsForTeacher(String teacherUid) {
    return _flagsRef
        .where('teacherUid', isEqualTo: teacherUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(StudentFlag.fromDoc).toList());
  }

  /// All flags for a specific school, newest first — powers the principal
  /// dashboard and analytics screen.
  Stream<List<StudentFlag>> streamAllFlags({String? schoolName}) {
    Query<Map<String, dynamic>> query = _flagsRef.orderBy(
      'createdAt',
      descending: true,
    );
    if (schoolName != null && schoolName.isNotEmpty) {
      query = query.where('schoolName', isEqualTo: schoolName);
    }
    return query.snapshots().map(
      (snap) => snap.docs
          .map(
            (doc) => StudentFlag.fromDoc(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList(),
    );
  }

  Future<void> createFlag(StudentFlag flag) async {
    await _flagsRef.add(flag.toMap());
  }

  /// Returns the new student's Firestore doc id, so a photo can be
  /// uploaded to a matching Storage path right after creation.
  Future<String> createStudent(Student student) async {
    final ref = await _studentsRef.add(student.toMap());
    return ref.id;
  }

  Future<void> updateStudentPhoto(String studentId, String photoUrl) async {
    await _studentsRef.doc(studentId).update({'photoUrl': photoUrl});
  }

  /// Edits an existing student's name/grade — principals only, enforced
  /// by firestore.rules (`write: if isPrincipal()` on /students/{id}).
  Future<void> updateStudent(String studentId, Student student) async {
    await _studentsRef.doc(studentId).update(student.toMap());
  }

  /// Removes a student record — principals only. Historical flags for
  /// this student are kept as-is (they're joined by name, not by id) so
  /// existing case history isn't silently deleted along with them.
  Future<void> deleteStudent(String studentId) async {
    await _studentsRef.doc(studentId).delete();
  }

  /// Full flag history for one student, across all teachers — powers
  /// the Student Profile screen.
  Stream<List<StudentFlag>> streamFlagsForStudent(String studentName) {
    return _flagsRef
        .where('studentName', isEqualTo: studentName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(StudentFlag.fromDoc).toList());
  }

  /// Called when a principal selects an intervention on the Select
  /// Intervention screen — updates status to "under review" and records
  /// which intervention type was chosen.
  Future<void> assignIntervention({
    required String flagId,
    required String interventionType,
  }) async {
    await _flagsRef.doc(flagId).update({
      'interventionType': interventionType,
      'status': FlagStatus.underReview.firestoreValue,
    });
  }

  Future<void> markResolved(String flagId) async {
    await _flagsRef.doc(flagId).update({
      'status': FlagStatus.resolved.firestoreValue,
    });
  }
}
