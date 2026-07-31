import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/flag.dart';
import '../../providers/stream_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/pill_badge.dart';
import '../common/profile_screen.dart';
import '../common/students_screen.dart';
import 'case_details_screen.dart';

/// The Intervention tab — was previously a dead bottom-nav entry
/// (tapping it did nothing). Lists every flag that still needs a
/// principal's action (reported or already under review) so an
/// intervention can be assigned, with resolved cases visible under a
/// second tab for reference.
class InterventionScreen extends ConsumerStatefulWidget {
  final AppUser user;
  final String? schoolName;

  const InterventionScreen({super.key, required this.user, this.schoolName});

  @override
  ConsumerState<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends ConsumerState<InterventionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 2) return; // already here
    Navigator.of(context).pop();
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StudentsScreen(user: widget.user)),
      );
    } else if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flagsAsync = ref.watch(
      allFlagsStreamProvider(widget.user.schoolName),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.principalPurple,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: const Row(
                children: [
                  Text(
                    'Intervention',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.principalPurple,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Needs Action'),
                  Tab(text: 'Resolved'),
                ],
              ),
            ),
            Expanded(
              child: flagsAsync.when(
                data: (allFlags) {
                  final needsAction =
                      allFlags
                          .where(
                            (f) =>
                                f.status == FlagStatus.reported ||
                                f.status == FlagStatus.underReview,
                          )
                          .toList()
                        ..sort(
                          (a, b) =>
                              b.severity.index.compareTo(a.severity.index),
                        );
                  final resolved =
                      allFlags
                          .where((f) => f.status == FlagStatus.resolved)
                          .toList()
                        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _CaseList(
                        flags: needsAction,
                        emptyText: 'No cases need attention right now.',
                        user: widget.user,
                      ),
                      _CaseList(
                        flags: resolved,
                        emptyText: 'No resolved cases yet.',
                        user: widget.user,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load cases right now.\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 2, onTap: _onNavTap),
    );
  }
}

class _CaseList extends StatelessWidget {
  final List<StudentFlag> flags;
  final String emptyText;
  final AppUser user;

  const _CaseList({
    required this.flags,
    required this.emptyText,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      itemCount: flags.length,
      itemBuilder: (context, index) =>
          _InterventionCard(flag: flags[index], user: user),
    );
  }
}

class _InterventionCard extends StatelessWidget {
  final StudentFlag flag;
  final AppUser user;

  const _InterventionCard({required this.flag, required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CaseDetailsScreen(flag: flag, user: user),
        ),
      ),
      child: Container(
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: flag.category.bg,
                  backgroundImage:
                      (flag.studentPhotoUrl != null &&
                          flag.studentPhotoUrl!.isNotEmpty)
                      ? NetworkImage(flag.studentPhotoUrl!)
                      : null,
                  child:
                      (flag.studentPhotoUrl == null ||
                          flag.studentPhotoUrl!.isEmpty)
                      ? Icon(Icons.person, color: flag.category.accent)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flag.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        flag.gradeSection,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PillBadge(
                      label: flag.severity.label,
                      color: flag.severity.color,
                    ),
                    const SizedBox(height: 4),
                    PillBadge(
                      label: flag.status.label,
                      color: flag.status.color,
                      filled: false,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                PillBadge(
                  label: flag.category.label,
                  color: flag.category.accent,
                  filled: false,
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(flag.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            if (flag.interventionType != null) ...[
              const SizedBox(height: 8),
              Text(
                'Intervention: ${flag.interventionType}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.principalPurple,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
