import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../models/student.dart';
import '../../providers/service_providers.dart';
import '../../providers/stream_providers.dart';
import '../../theme/app_theme.dart';
import 'add_student_screen.dart';
import 'student_profile_screen.dart';

/// Full student roster. Both roles see the same list for now (a school
/// is small enough that this is simpler than modeling class assignments);
/// only principals can add, edit, or remove students.
class StudentsScreen extends ConsumerStatefulWidget {
  final AppUser user;

  const StudentsScreen({super.key, required this.user});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove student?'),
        content: Text(
          'This will permanently remove ${student.fullName} from the roster. '
          'Their existing flag history is kept for record-keeping.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.urgentRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(flagServiceProvider).deleteStudent(student.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.fullName} was removed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not remove student: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrincipal = widget.user.role == UserRole.principal;
    final accent = isPrincipal ? AppColors.principalPurple : AppColors.teacherGreen;
    final studentsAsync = ref.watch(studentsStreamProvider(widget.user.schoolName));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        title: const Text('Students'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search students...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              data: (allStudents) {
                final students = allStudents
                    .where((s) => s.fullName.toLowerCase().contains(_query))
                    .toList();

                if (students.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        isPrincipal
                            ? 'No students yet. Tap + to add your first student.'
                            : 'No students yet — ask your principal to add some.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEDEFF5)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: accent.withValues(alpha: 0.12),
                          backgroundImage:
                              (student.photoUrl != null && student.photoUrl!.isNotEmpty)
                                  ? NetworkImage(student.photoUrl!)
                                  : null,
                          child: (student.photoUrl == null || student.photoUrl!.isEmpty)
                              ? Icon(Icons.person, color: accent)
                              : null,
                        ),
                        title: Text(student.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(student.gradeSection),
                        trailing: isPrincipal
                            ? PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AddStudentScreen(student: student),
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    _confirmDelete(student);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 10),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline,
                                            size: 18, color: AppColors.urgentRed),
                                        SizedBox(width: 10),
                                        Text('Delete',
                                            style: TextStyle(color: AppColors.urgentRed)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                StudentProfileScreen(student: student, viewer: widget.user),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load students: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: isPrincipal
          ? FloatingActionButton(
              backgroundColor: accent,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddStudentScreen(schoolName: widget.user.schoolName)),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
