import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/flag.dart';
import '../models/student.dart';
import 'service_providers.dart';

final studentsStreamProvider = StreamProvider.family<List<Student>, String?>((
  ref,
  schoolName,
) {
  return ref.watch(flagServiceProvider).streamStudents(schoolName: schoolName);
});

final allFlagsStreamProvider =
    StreamProvider.family<List<StudentFlag>, String?>((ref, schoolName) {
      return ref
          .watch(flagServiceProvider)
          .streamAllFlags(schoolName: schoolName);
    });

final teacherFlagsStreamProvider =
    StreamProvider.family<List<StudentFlag>, String>((ref, teacherUid) {
      return ref.watch(flagServiceProvider).streamFlagsForTeacher(teacherUid);
    });

final studentFlagsStreamProvider =
    StreamProvider.family<List<StudentFlag>, String>((ref, studentName) {
      return ref.watch(flagServiceProvider).streamFlagsForStudent(studentName);
    });
