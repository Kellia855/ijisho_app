import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/flag.dart';
import '../../models/student.dart';
import '../../providers/service_providers.dart';
import '../../providers/stream_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pill_badge.dart';
import '../teacher/log_issue_sheet.dart';
import 'add_student_screen.dart';

/// Shows a student's full flag history across all teachers, plus a
/// quick "Log Issue" shortcut for teachers. Reached by tapping a
/// student on either role's Students tab.
class StudentProfileScreen extends ConsumerWidget {
  final Student student;
  final AppUser viewer;

  const StudentProfileScreen({super.key, required this.student, required this.viewer});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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

    if (confirmed != true) return;

    try {
      await ref.read(flagServiceProvider).deleteStudent(student.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.fullName} was removed.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not remove student: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent =
        viewer.role == UserRole.teacher ? AppColors.teacherGreen : AppColors.principalPurple;
    final flagsAsync = ref.watch(studentFlagsStreamProvider(student.fullName));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: accent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    backgroundImage:
                        (student.photoUrl != null && student.photoUrl!.isNotEmpty)
                            ? NetworkImage(student.photoUrl!)
                            : null,
                    child: (student.photoUrl == null || student.photoUrl!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.fullName,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(student.gradeSection,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (viewer.role == UserRole.principal)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddStudentScreen(student: student),
                            ),
                          );
                        } else if (value == 'delete') {
                          _confirmDelete(context, ref);
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
                              Icon(Icons.delete_outline, size: 18, color: AppColors.urgentRed),
                              SizedBox(width: 10),
                              Text('Delete', style: TextStyle(color: AppColors.urgentRed)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(
              child: flagsAsync.when(
                data: (flags) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                    children: [
                      if (flags.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No flags on record for this student yet.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      else ...[
                        Text('${flags.length} flag${flags.length == 1 ? '' : 's'} on record',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 12),
                        ...flags.map((f) => _HistoryCard(flag: f)),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Could not load flags: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: viewer.role == UserRole.teacher
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.teacherGreen,
              onPressed: () => LogIssueSheet.show(
                context,
                teacherUid: viewer.uid,
                teacherName: viewer.fullName,
                preselectedStudent: student,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Log Issue', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final StudentFlag flag;

  const _HistoryCard({required this.flag});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: flag.category.bg, shape: BoxShape.circle),
                child: Icon(flag.category.icon, color: flag.category.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(flag.category.label,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('by ${flag.teacherName.isEmpty ? "Unknown" : flag.teacherName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PillBadge(label: flag.severity.label, color: flag.severity.color),
                  const SizedBox(height: 4),
                  PillBadge(label: flag.status.label, color: flag.status.color, filled: false),
                ],
              ),
            ],
          ),
          if (flag.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${flag.note}"',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
          ],
          const SizedBox(height: 6),
          Text(
            DateFormat('MMM d, yyyy \u00b7 h:mm a').format(flag.createdAt),
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          if (flag.interventionType != null) ...[
            const SizedBox(height: 6),
            Text('Intervention: ${flag.interventionType}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.principalPurple)),
          ],
        ],
      ),
    );
  }
}
