import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../localization/app_strings.dart';
import '../../models/app_user.dart';
import '../../models/flag.dart';
import '../../providers/language_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/stream_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/pill_badge.dart';
import '../common/profile_screen.dart';
import '../common/students_screen.dart';
import '../role_select_screen.dart';
import 'analytics_screen.dart';
import 'case_details_screen.dart';
import 'intervention_screen.dart';

/// Principal Dashboard — matches the "Welcome back to your dashboard"
/// screen: purple top bar + stats card, search, category filter chips,
/// and the Attention Required list sorted by severity.
class PrincipalHomeScreen extends ConsumerStatefulWidget {
  final AppUser user;

  const PrincipalHomeScreen({super.key, required this.user});

  @override
  ConsumerState<PrincipalHomeScreen> createState() => _PrincipalHomeScreenState();
}

class _PrincipalHomeScreenState extends ConsumerState<PrincipalHomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  FlagCategory? _activeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        MaterialPageRoute(builder: (_) => InterventionScreen(user: widget.user)),
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
    final flagsAsync = ref.watch(allFlagsStreamProvider(widget.user.schoolName));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: flagsAsync.when(
          data: (allFlags) {
            final totalStudents = allFlags.map((f) => f.studentName).toSet().length;
            final atRisk = allFlags
                .where((f) =>
                    f.severity == FlagSeverity.urgent || f.severity == FlagSeverity.warning)
                .map((f) => f.studentName)
                .toSet()
                .length;
            final urgentCount =
                allFlags.where((f) => f.severity == FlagSeverity.urgent).length;

            final filtered = allFlags.where((f) {
              final matchesQuery = f.studentName.toLowerCase().contains(_query);
              final matchesFilter =
                  _activeFilter == null || f.category.broadCategory == _activeFilter;
              return matchesQuery && matchesFilter;
            }).toList()
              ..sort((a, b) => b.severity.index.compareTo(a.severity.index));

            return Column(
              children: [
                _TopSection(
                  user: widget.user,
                  language: language,
                  totalStudents: totalStudents,
                  atRisk: atRisk,
                  urgentCount: urgentCount,
                  onLogout: _logOut,
                  onToggleLanguage: () => ref.read(appLanguageProvider.notifier).toggle(),
                  onAnalytics: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AnalyticsScreen(schoolName: widget.user.schoolName),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _query = v.toLowerCase()),
                          decoration: const InputDecoration(
                            hintText: 'Search student records...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _FilterChip(
                                label: 'All',
                                selected: _activeFilter == null,
                                onTap: () => setState(() => _activeFilter = null),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Financial',
                                selected: _activeFilter == FlagCategory.financial,
                                onTap: () =>
                                    setState(() => _activeFilter = FlagCategory.financial),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Academic',
                                selected: _activeFilter == FlagCategory.academic,
                                onTap: () =>
                                    setState(() => _activeFilter = FlagCategory.academic),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Attendance',
                                selected: _activeFilter == FlagCategory.attendance,
                                onTap: () =>
                                    setState(() => _activeFilter = FlagCategory.attendance),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(t('Attention Required', language),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 12),
                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No flagged students match this view yet.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        else
                          ...filtered.map((f) => _AttentionCard(
                                flag: f,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CaseDetailsScreen(flag: f, user: widget.user),
                                  ),
                                ),
                              )),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load student records right now.\n$e',
                style: const TextStyle(color: AppColors.urgentRed),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 0, onTap: _onNavTap),
    );
  }
}

class _TopSection extends StatelessWidget {
  final AppUser user;
  final AppLanguage language;
  final int totalStudents;
  final int atRisk;
  final int urgentCount;
  final VoidCallback onLogout;
  final VoidCallback onToggleLanguage;
  final VoidCallback onAnalytics;

  const _TopSection({
    required this.user,
    required this.language,
    required this.totalStudents,
    required this.atRisk,
    required this.urgentCount,
    required this.onLogout,
    required this.onToggleLanguage,
    required this.onAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.principalPurple,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              IconButton(
                onPressed: onToggleLanguage,
                icon: const Icon(Icons.translate, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white, size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(' ${user.fullName}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(t('Welcome back!', language),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onAnalytics,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.principalPurple,
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.bar_chart, size: 16),
                label: Text(t('Analytics', language), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '$totalStudents',
                  label: t('Total Students', language),
                  bg: Colors.white,
                  valueColor: AppColors.principalPurple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '$atRisk',
                  label: t('At Risk', language),
                  bg: const Color(0xFFDFF3E6),
                  valueColor: AppColors.fineGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '$urgentCount',
                  label: t('Urgent', language),
                  bg: const Color(0xFFFBDCE1),
                  valueColor: AppColors.urgentRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color bg;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.bg,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.principalPurple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.principalPurple : const Color(0xFFE2E5EC)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final StudentFlag flag;
  final VoidCallback onTap;

  const _AttentionCard({required this.flag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Container(
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: flag.severity.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: flag.category.bg,
                          backgroundImage: (flag.studentPhotoUrl != null &&
                                  flag.studentPhotoUrl!.isNotEmpty)
                              ? NetworkImage(flag.studentPhotoUrl!)
                              : null,
                          child: (flag.studentPhotoUrl == null ||
                                  flag.studentPhotoUrl!.isEmpty)
                              ? Icon(Icons.person, color: flag.category.accent)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(flag.studentName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 14)),
                              Text(flag.gradeSection,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              PillBadge(
                                label: flag.category.label,
                                color: flag.category.accent,
                                filled: false,
                              ),
                            ],
                          ),
                        ),
                        PillBadge(label: flag.severity.label, color: flag.severity.color),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
