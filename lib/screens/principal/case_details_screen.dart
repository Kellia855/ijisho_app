import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/flag.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/pill_badge.dart';
import '../common/profile_screen.dart';
import '../common/students_screen.dart';
import 'select_intervention_screen.dart';

class CaseDetailsScreen extends StatelessWidget {
  final StudentFlag flag;
  final AppUser user;

  const CaseDetailsScreen({super.key, required this.flag, required this.user});

  void _onNavTap(BuildContext context, int index) {
    if (index == 2) {
      // Already in the Intervention flow — pop back to the queue
      // instead of stacking another copy on top of it.
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop();
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StudentsScreen(user: user)),
      );
    } else if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
      );
    }
  }

  String get _severityLabel => switch (flag.severity) {
        FlagSeverity.urgent => 'High',
        FlagSeverity.warning => 'Medium',
        FlagSeverity.fine => 'Low',
      };

  String get _ordinal {
    final n = flag.flagCountThisTerm;
    if (n % 10 == 1 && n % 100 != 11) return '${n}st';
    if (n % 10 == 2 && n % 100 != 12) return '${n}nd';
    if (n % 10 == 3 && n % 100 != 13) return '${n}rd';
    return '${n}th';
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
                    child: Text('Case Details',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                  const Icon(Icons.translate, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  const CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white24,
                    child: Text('P', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: flag.category.bg,
                          backgroundImage: (flag.studentPhotoUrl != null &&
                                  flag.studentPhotoUrl!.isNotEmpty)
                              ? NetworkImage(flag.studentPhotoUrl!)
                              : null,
                          child: (flag.studentPhotoUrl == null ||
                                  flag.studentPhotoUrl!.isEmpty)
                              ? Icon(Icons.person, size: 30, color: flag.category.accent)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(flag.studentName,
                                        style: const TextStyle(
                                            fontSize: 17, fontWeight: FontWeight.bold)),
                                  ),
                                  const PillBadge(label: 'FLAGGED', color: AppColors.urgentRed),
                                ],
                              ),
                              Text(flag.gradeSection,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(flag.createdAt),
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Case Severity',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SeverityTile(
                          bg: AppColors.absentBg,
                          iconColor: AppColors.urgentRed,
                          icon: Icons.warning_amber_rounded,
                          tag: 'URGENT',
                          tagColor: AppColors.urgentRed,
                          value: _severityLabel,
                          caption: 'Severity Index',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SeverityTile(
                          bg: AppColors.strugglingBg,
                          iconColor: AppColors.principalPurple,
                          icon: Icons.history,
                          tag: 'REPEAT',
                          tagColor: AppColors.principalPurple,
                          value: _ordinal,
                          caption: 'Flag this term',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Teacher's Observations",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: IntrinsicHeight(
                      child: Container(
                      color: Colors.white,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(width: 4, color: AppColors.principalPurple),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                        future: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(flag.teacherUid)
                                            .get(),
                                        builder: (context, snapshot) {
                                          final photoUrl = snapshot.data?.data()?['photoUrl']
                                              as String?;
                                          return CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppColors.principalPurpleLight,
                                            backgroundImage:
                                                (photoUrl != null && photoUrl.isNotEmpty)
                                                    ? NetworkImage(photoUrl)
                                                    : null,
                                            child: (photoUrl == null || photoUrl.isEmpty)
                                                ? const Icon(Icons.person,
                                                    size: 14, color: AppColors.principalPurple)
                                                : null,
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Mr. ${flag.teacherName.isEmpty ? "Teacher" : flag.teacherName}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600, fontSize: 13)),
                                            const Text('Class Teacher',
                                                style: TextStyle(
                                                    fontSize: 11, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                      Text(DateFormat('MMM d, HH:mm').format(flag.createdAt),
                                          style: const TextStyle(
                                              fontSize: 11, color: AppColors.textMuted)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    flag.note.isEmpty
                                        ? 'No additional notes were added.'
                                        : '"${flag.note}"',
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic, fontSize: 13),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      PillBadge(
                                        label: flag.category.label,
                                        color: flag.category.accent,
                                        filled: false,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SelectInterventionScreen(flag: flag, user: user),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.principalPurple,
                        foregroundColor: Colors.white,
                        shape:
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.warning_amber_rounded, size: 18),
                      label: const Text('Select Intervention'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Assigning an intervention will notify the Class Teacher and the Counselor immediately.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 2, onTap: (i) => _onNavTap(context, i)),
    );
  }
}

class _SeverityTile extends StatelessWidget {
  final Color bg;
  final Color iconColor;
  final IconData icon;
  final String tag;
  final Color tagColor;
  final String value;
  final String caption;

  const _SeverityTile({
    required this.bg,
    required this.iconColor,
    required this.icon,
    required this.tag,
    required this.tagColor,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 20),
              Text(tag,
                  style: TextStyle(
                      color: tagColor, fontWeight: FontWeight.w700, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: iconColor)),
          Text(caption, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
