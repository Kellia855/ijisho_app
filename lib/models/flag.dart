import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The category a teacher selects when logging an issue. Matches the
/// "Report Issues" grid (Absent, No Uniform, No Lunch, Struggling) plus
/// the broader categories used on the principal side (Financial,
/// Academic, Attendance, Behavioral) since a flag can be re-categorized
/// or aggregated at a higher level for analytics.
enum FlagCategory {
  absent,
  noUniform,
  noLunch,
  struggling,
  financial,
  academic,
  attendance,
  behavioral,
}

extension FlagCategoryX on FlagCategory {
  String get label => switch (this) {
    FlagCategory.absent => 'Absent',
    FlagCategory.noUniform => 'No Uniform',
    FlagCategory.noLunch => 'No Lunch',
    FlagCategory.struggling => 'Struggling in Class',
    FlagCategory.financial => 'Financial Stress',
    FlagCategory.academic => 'Academic Struggle',
    FlagCategory.attendance => 'Attendance Issues',
    FlagCategory.behavioral => 'Behavioral',
  };

  String get subtitle => switch (this) {
    FlagCategory.absent => 'Daily Attendance',
    FlagCategory.noUniform => 'Dress Code',
    FlagCategory.noLunch => 'Food Support',
    FlagCategory.struggling => 'Academic Help',
    _ => '',
  };

  IconData get icon => switch (this) {
    FlagCategory.absent => Icons.person_off_outlined,
    FlagCategory.noUniform => Icons.checkroom_outlined,
    FlagCategory.noLunch => Icons.restaurant_outlined,
    FlagCategory.struggling => Icons.trending_down,
    FlagCategory.financial => Icons.payments_outlined,
    FlagCategory.academic => Icons.menu_book_outlined,
    FlagCategory.attendance => Icons.event_busy_outlined,
    FlagCategory.behavioral => Icons.psychology_outlined,
  };

  Color get accent => switch (this) {
    FlagCategory.absent => AppColors.absentAccent,
    FlagCategory.noUniform => AppColors.noUniformAccent,
    FlagCategory.noLunch => AppColors.noLunchAccent,
    FlagCategory.struggling => AppColors.strugglingAccent,
    FlagCategory.financial => AppColors.financialAccent,
    FlagCategory.academic => AppColors.academicAccent,
    FlagCategory.attendance => AppColors.attendanceAccent,
    FlagCategory.behavioral => AppColors.behavioralAccent,
  };

  Color get bg => switch (this) {
    FlagCategory.absent => AppColors.absentBg,
    FlagCategory.noUniform => AppColors.noUniformBg,
    FlagCategory.noLunch => AppColors.noLunchBg,
    FlagCategory.struggling => AppColors.strugglingBg,
    _ => accent.withValues(alpha: 0.12),
  };

  String get firestoreValue => name;

  /// Maps a teacher-facing category (the four options on the "Report
  /// Issues" grid) to the broader principal-facing bucket it belongs to
  /// (the Financial / Academic / Attendance filter chips on the
  /// dashboard). Every flag a teacher can actually create is one of
  /// [absent], [noUniform], [noLunch] or [struggling] — without this
  /// mapping, the principal's category filters would compare against
  /// [financial]/[academic]/[attendance] directly, which no flag ever
  /// has, so every filter would silently show zero results.
  FlagCategory get broadCategory => switch (this) {
    FlagCategory.absent => FlagCategory.attendance,
    FlagCategory.noUniform => FlagCategory.financial,
    FlagCategory.noLunch => FlagCategory.financial,
    FlagCategory.struggling => FlagCategory.academic,
    FlagCategory.financial => FlagCategory.financial,
    FlagCategory.academic => FlagCategory.academic,
    FlagCategory.attendance => FlagCategory.attendance,
    FlagCategory.behavioral => FlagCategory.behavioral,
  };

  static FlagCategory fromFirestore(String value) => FlagCategory.values
      .firstWhere((c) => c.name == value, orElse: () => FlagCategory.academic);
}

/// Overall risk severity, shown as the URGENT / WARNING / FINE badges
/// on the principal dashboard and analytics pie chart.
enum FlagSeverity { urgent, warning, fine }

extension FlagSeverityX on FlagSeverity {
  String get label => switch (this) {
    FlagSeverity.urgent => 'URGENT',
    FlagSeverity.warning => 'WARNING',
    FlagSeverity.fine => 'FINE',
  };

  Color get color => switch (this) {
    FlagSeverity.urgent => AppColors.urgentRed,
    FlagSeverity.warning => AppColors.warningOrange,
    FlagSeverity.fine => AppColors.fineGreen,
  };

  String get firestoreValue => name;

  static FlagSeverity fromFirestore(String value) => FlagSeverity.values
      .firstWhere((s) => s.name == value, orElse: () => FlagSeverity.warning);
}

/// Status shown on the Flagging History cards (REPORTED / UNDER REVIEW /
/// RESOLVED) and updated once a principal selects an intervention.
enum FlagStatus { reported, underReview, resolved }

extension FlagStatusX on FlagStatus {
  String get label => switch (this) {
    FlagStatus.reported => 'REPORTED',
    FlagStatus.underReview => 'UNDER REVIEW',
    FlagStatus.resolved => 'RESOLVED',
  };

  Color get color => switch (this) {
    FlagStatus.reported => AppColors.urgentRed,
    FlagStatus.underReview => AppColors.fineGreen,
    FlagStatus.resolved => AppColors.textMuted,
  };

  String get firestoreValue => name;

  static FlagStatus fromFirestore(String value) => FlagStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => FlagStatus.reported,
  );
}

/// A single flagged concern about a student, created by a teacher and
/// acted on by a principal. Stored in the top-level `flags` collection.
class StudentFlag {
  final String id;
  final String studentName;
  final String gradeSection;
  final FlagCategory category;
  final FlagSeverity severity;
  final FlagStatus status;
  final String note;
  final String teacherName;
  final String teacherUid;
  final DateTime createdAt;
  final int flagCountThisTerm; // for the "3rd flag this term" repeat badge
  final String? interventionType;
  final String? studentPhotoUrl;
  final String? schoolName;

  const StudentFlag({
    required this.id,
    required this.studentName,
    required this.gradeSection,
    required this.category,
    required this.severity,
    required this.status,
    required this.note,
    required this.teacherName,
    required this.teacherUid,
    required this.createdAt,
    this.flagCountThisTerm = 1,
    this.interventionType,
    this.studentPhotoUrl,
    this.schoolName,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentName': studentName,
      'gradeSection': gradeSection,
      'category': category.firestoreValue,
      'severity': severity.firestoreValue,
      'status': status.firestoreValue,
      'note': note,
      'teacherName': teacherName,
      'teacherUid': teacherUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'flagCountThisTerm': flagCountThisTerm,
      'interventionType': ?interventionType,
      'studentPhotoUrl': ?studentPhotoUrl,
      'schoolName': ?schoolName,
    };
  }

  factory StudentFlag.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return StudentFlag(
      id: doc.id,
      studentName: data['studentName'] as String? ?? 'Unknown Student',
      gradeSection: data['gradeSection'] as String? ?? '',
      category: FlagCategoryX.fromFirestore(data['category'] as String? ?? ''),
      severity: FlagSeverityX.fromFirestore(data['severity'] as String? ?? ''),
      status: FlagStatusX.fromFirestore(data['status'] as String? ?? ''),
      note: data['note'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      teacherUid: data['teacherUid'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      flagCountThisTerm: (data['flagCountThisTerm'] as num?)?.toInt() ?? 1,
      interventionType: data['interventionType'] as String?,
      studentPhotoUrl: data['studentPhotoUrl'] as String?,
      schoolName: data['schoolName'] as String?,
    );
  }
}
