import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/flag.dart';
import '../models/student.dart';
import 'service_providers.dart';

final studentsStreamProvider = StreamProvider<List<Student>>((ref) {
  return ref.watch(flagServiceProvider).streamStudents();
});

final allFlagsStreamProvider = StreamProvider<List<StudentFlag>>((ref) {
  return ref.watch(flagServiceProvider).streamAllFlags();
});

final teacherFlagsStreamProvider =
    StreamProvider.family<List<StudentFlag>, String>((ref, teacherUid) {
  return ref.watch(flagServiceProvider).streamFlagsForTeacher(teacherUid);
});

final studentFlagsStreamProvider =
    StreamProvider.family<List<StudentFlag>, String>((ref, studentName) {
  return ref.watch(flagServiceProvider).streamFlagsForStudent(studentName);
});
