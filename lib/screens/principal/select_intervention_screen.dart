import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../models/flag.dart';
import '../../providers/service_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/pill_badge.dart';
import '../common/profile_screen.dart';
import '../common/students_screen.dart';

class _InterventionOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color bg;

  const _InterventionOption(this.title, this.subtitle, this.icon, this.accent, this.bg);
}

class SelectInterventionScreen extends ConsumerStatefulWidget {
  final StudentFlag flag;
  final AppUser user;

  const SelectInterventionScreen({super.key, required this.flag, required this.user});

  @override
  ConsumerState<SelectInterventionScreen> createState() => _SelectInterventionScreenState();
}

class _SelectInterventionScreenState extends ConsumerState<SelectInterventionScreen> {
  bool _isSubmitting = false;

  void _onNavTap(int index) {
    if (index == 2) {
      Navigator.of(context).pop();
      return;
    }
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

  static const _options = [
    _InterventionOption(
      'Fee Waiver',
      'Request full or partial tuition assistance.',
      Icons.payments_outlined,
      AppColors.fineGreen,
      Color(0xFFDFF3E6),
    ),
    _InterventionOption(
      'Parent Meeting',
      'Schedule a physical or virtual conference.',
      Icons.groups_outlined,
      Color(0xFFE05A8A),
      Color(0xFFFCE4EF),
    ),
    _InterventionOption(
      'Counselling',
      'Emotional and psychological support sessions.',
      Icons.favorite_outline,
      AppColors.urgentRed,
      AppColors.absentBg,
    ),
    _InterventionOption(
      'NGO Referral',
      'Connect with external educational partners.',
      Icons.link,
      AppColors.attendanceAccent,
      Color(0xFFE3EBFC),
    ),
  ];

  Future<void> _selectOption(_InterventionOption option) async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(flagServiceProvider).assignIntervention(
        flagId: widget.flag.id,
        interventionType: option.title,
      );
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Intervention assigned'),
            content: Text(
              '${option.title} has been assigned for ${widget.flag.studentName}. '
              'The class teacher and counselor have been notified.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                    ..pop()
                    ..pop();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not assign: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.principalPurple,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text('Select Intervention',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                  const Icon(Icons.translate, color: Colors.white, size: 20),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: widget.flag.category.bg,
                              backgroundImage: (widget.flag.studentPhotoUrl != null &&
                                      widget.flag.studentPhotoUrl!.isNotEmpty)
                                  ? NetworkImage(widget.flag.studentPhotoUrl!)
                                  : null,
                              child: (widget.flag.studentPhotoUrl == null ||
                                      widget.flag.studentPhotoUrl!.isEmpty)
                                  ? Icon(Icons.person,
                                      color: widget.flag.category.accent, size: 24)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.flag.studentName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(widget.flag.gradeSection,
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            PillBadge(
                                label: widget.flag.severity.label,
                                color: widget.flag.severity.color),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('AVAILABLE INTERVENTIONS',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      ..._options.map((option) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _isSubmitting ? null : () => _selectOption(option),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: option.bg,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(option.icon, color: option.accent),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(option.title,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700, fontSize: 14)),
                                            Text(option.subtitle,
                                                style: const TextStyle(
                                                    fontSize: 12, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right,
                                          color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3EBFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.attendanceAccent),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Selecting an option will create a new case file for review by the School Principal and Head of Student Welfare.',
                                style: TextStyle(fontSize: 12, color: AppColors.textDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isSubmitting)
                    Container(
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 2, onTap: _onNavTap),
    );
  }
}
