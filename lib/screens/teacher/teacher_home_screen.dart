import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../localization/app_strings.dart';
import '../../models/app_user.dart';
import '../../models/flag.dart';
import '../../models/student.dart';
import '../../providers/language_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/stream_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/pill_badge.dart';
import '../common/profile_screen.dart';
import '../common/students_screen.dart';
import '../role_select_screen.dart';
import 'flagging_history_screen.dart';
import 'log_issue_sheet.dart';

/// Teacher Dashboard — matches the "Welcome back, Teacher ..." screen:
/// purple top bar, green welcome card, an urgent-flag banner for the
/// selected student, the Report Issues grid, and Recent Submissions.
class TeacherHomeScreen extends ConsumerStatefulWidget {
  final AppUser user;

  const TeacherHomeScreen({super.key, required this.user});

  @override
  ConsumerState<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends ConsumerState<TeacherHomeScreen> {
  Student? _selectedStudent;

  static const _reportCategories = [
    FlagCategory.absent,
    FlagCategory.noUniform,
    FlagCategory.noLunch,
    FlagCategory.struggling,
  ];

  Future<void> _logOut() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
        (route) => false,
      );
    }
  }

  void _onNavTap(int index) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StudentsScreen(user: widget.user)),
      );
    } else if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FlaggingHistoryScreen(user: widget.user),
        ),
      );
    } else if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final studentsAsync = ref.watch(studentsStreamProvider(widget.user.schoolName));
    final flagsAsync = ref.watch(teacherFlagsStreamProvider(widget.user.uid));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              onLogout: _logOut,
              onToggleLanguage: () => ref.read(appLanguageProvider.notifier).toggle(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WelcomeCard(user: widget.user, language: language),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(t('Select Student', language),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          studentsAsync.when(
                            data: (students) {
                              if (_selectedStudent == null && students.isNotEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) setState(() => _selectedStudent = students.first);
                                });
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E5EC)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<Student>(
                                    value: _selectedStudent,
                                    isExpanded: true,
                                    hint: const Text('-- Select Student --'),
                                    items: students
                                        .map((s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(s.fullName),
                                            ))
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _selectedStudent = value),
                                  ),
                                ),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('Could not load students: $e'),
                          ),
                          const SizedBox(height: 16),
                          _UrgentBanner(teacherUid: widget.user.uid),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t('Report Issues', language),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 16)),
                              GestureDetector(
                                onTap: () => _onNavTap(2),
                                child: Text(t('View All', language),
                                    style: const TextStyle(
                                        color: AppColors.teacherGreen,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: _reportCategories
                                .map((c) => _ReportIssueCard(
                                      category: c,
                                      onTap: () => LogIssueSheet.show(
                                        context,
                                        teacherUid: widget.user.uid,
                                        teacherName: widget.user.fullName,
                                        schoolName: widget.user.schoolName,
                                        preselectedStudent: _selectedStudent,
                                        preselectedCategory: c,
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                          Text(t('Recent Submissions', language),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 12),
                          flagsAsync.when(
                            data: (allFlags) {
                              final flags = allFlags.take(5).toList();
                              if (flags.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'No submissions yet — flag a student above to get started.',
                                    style: TextStyle(color: AppColors.textMuted),
                                  ),
                                );
                              }
                              return Column(
                                children: flags
                                    .map((f) => _RecentSubmissionTile(flag: f))
                                    .toList(),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('Could not load submissions: $e'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.roleBlue,
        onPressed: () => LogIssueSheet.show(
          context,
          teacherUid: widget.user.uid,
          teacherName: widget.user.fullName,
          schoolName: widget.user.schoolName,
          preselectedStudent: _selectedStudent,
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 0, onTap: _onNavTap),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onToggleLanguage;

  const _TopBar({required this.onLogout, required this.onToggleLanguage});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.principalPurple,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
          ),
          const Expanded(
            child: Text(
              'IJISHO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            onPressed: onToggleLanguage,
            icon: const Icon(Icons.translate, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final AppUser user;
  final AppLanguage language;

  const _WelcomeCard({required this.user, required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.teacherGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                ? NetworkImage(user.photoUrl!)
                : null,
            child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.white, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('Welcome back!', language),
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text(
                  ' ${user.fullName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('Teacher',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentBanner extends ConsumerWidget {
  final String teacherUid;

  const _UrgentBanner({required this.teacherUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(teacherFlagsStreamProvider(teacherUid));

    return flagsAsync.when(
      data: (allFlags) {
        final urgent = allFlags.where((f) => f.severity == FlagSeverity.urgent).toList();
        if (urgent.isEmpty) return const SizedBox.shrink();
        final flag = urgent.first;

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Container(
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: AppColors.urgentRed),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(flag.studentName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            const PillBadge(label: 'URGENT', color: AppColors.urgentRed),
                          ],
                        ),
                        Text(flag.gradeSection,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.absentBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: AppColors.urgentRed, size: 16),
                              SizedBox(width: 6),
                              Text('Multiple flags raised',
                                  style: TextStyle(
                                      color: AppColors.urgentRed,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ReportIssueCard extends StatelessWidget {
  final FlagCategory category;
  final VoidCallback onTap;

  const _ReportIssueCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFEDEFF5)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration:
                              BoxDecoration(color: category.bg, shape: BoxShape.circle),
                          child: Icon(category.icon, color: category.accent, size: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(category.label,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        if (category.subtitle.isNotEmpty)
                          Text(category.subtitle,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                Container(height: 3, color: category.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentSubmissionTile extends StatelessWidget {
  final StudentFlag flag;

  const _RecentSubmissionTile({required this.flag});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEFF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: flag.category.bg, shape: BoxShape.circle),
            child: Icon(flag.category.icon, color: flag.category.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(flag.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  '${flag.category.label} \u00b7 ${DateFormat('h:mm a').format(flag.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
