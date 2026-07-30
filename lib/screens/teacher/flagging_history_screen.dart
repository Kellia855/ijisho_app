import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../localization/app_strings.dart';
import '../../models/flag.dart';
import '../../providers/language_provider.dart';
import '../../providers/stream_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/pill_badge.dart';
import '../common/profile_screen.dart';
import '../common/students_screen.dart';
import 'log_issue_sheet.dart';

class FlaggingHistoryScreen extends ConsumerStatefulWidget {
  final AppUser user;

  const FlaggingHistoryScreen({super.key, required this.user});

  @override
  ConsumerState<FlaggingHistoryScreen> createState() => _FlaggingHistoryScreenState();
}

class _FlaggingHistoryScreenState extends ConsumerState<FlaggingHistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 2) return;
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
    final language = ref.watch(appLanguageProvider);
    final flagsAsync = ref.watch(teacherFlagsStreamProvider(widget.user.uid));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.teacherGreenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: AppColors.teacherGreen, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('IJISHO',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => ref.read(appLanguageProvider.notifier).toggle(),
                    icon: const Icon(Icons.translate, size: 20, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('Flagging History', language),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Review all student intervention requests and flagged concerns.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _query = v.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: t('Search students...', language),
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.teacherGreenLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_list, size: 18, color: AppColors.teacherGreen),
                            const SizedBox(width: 6),
                            Text(t('Filter', language),
                                style: const TextStyle(
                                    color: AppColors.teacherGreen,
                                    fontWeight: FontWeight.w600)),
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
                data: (allFlags) {
                  final flags = allFlags
                      .where((f) => f.studentName.toLowerCase().contains(_query))
                      .toList();

                  if (flags.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No flags yet. Tap + to log your first student issue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                    itemCount: flags.length,
                    itemBuilder: (context, index) => _FlagCard(flag: flags[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Could not load flags: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.teacherGreen,
        onPressed: () => LogIssueSheet.show(
          context,
          teacherUid: widget.user.uid,
          teacherName: widget.user.fullName,
          schoolName: widget.user.schoolName,
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        activeColor: AppColors.teacherGreen,
        onTap: _onNavTap,
      ),
    );
  }
}

class _FlagCard extends StatelessWidget {
  final StudentFlag flag;

  const _FlagCard({required this.flag});

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: flag.category.bg, shape: BoxShape.circle),
                child: Icon(flag.category.icon, color: flag.category.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(flag.studentName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(flag.gradeSection,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              PillBadge(label: flag.status.label, color: flag.status.color),
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
              const SizedBox(width: 8),
              Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM d, yyyy').format(flag.createdAt),
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          if (flag.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${flag.note}"',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
