import 'package:flutter/material.dart';

/// Central place for IJISHO's brand colors so screens stay consistent
/// with the Figma prototype: blue for the neutral role-select screen,
/// green for the Teacher portal, purple for the Principal portal.
class AppColors {
  AppColors._();

  static const Color roleBlue = Color(0xFF3B6DF0);
  static const Color backgroundLight = Color(0xFFEFF3FF);

  static const Color teacherGreen = Color(0xFF1E8E4A);
  static const Color teacherGreenLight = Color(0xFFE3F5E9);

  static const Color principalPurple = Color(0xFF6C3CE0);
  static const Color principalPurpleLight = Color(0xFFF0E9FB);

  static const Color urgentRed = Color(0xFFE0364F);
  static const Color warningOrange = Color(0xFFE0A030);
  static const Color fineGreen = Color(0xFF2FA85A);

  static const Color textDark = Color(0xFF1A1D29);
  static const Color textMuted = Color(0xFF6B7280);

  // Issue-category colors (Report Issues grid, tags on flag cards)
  static const Color absentAccent = Color(0xFFE0364F);
  static const Color absentBg = Color(0xFFFCE9EC);

  static const Color noUniformAccent = Color(0xFFE0A030);
  static const Color noUniformBg = Color(0xFFFDF1DE);

  static const Color noLunchAccent = Color(0xFFC99A2E);
  static const Color noLunchBg = Color(0xFFFBF3D9);

  static const Color strugglingAccent = Color(0xFF8B5CF6);
  static const Color strugglingBg = Color(0xFFF1EAFC);

  static const Color financialAccent = Color(0xFFC99A2E);
  static const Color academicAccent = Color(0xFF6C63FF);
  static const Color attendanceAccent = Color(0xFF3B6DF0);
  static const Color behavioralAccent = Color(0xFF2FA88F);

  // Dashboard active-tab pill (blue, as used on most dashboard screens)
  static const Color navActiveBlue = Color(0xFF3B5BFB);
}

class AppTheme {
  AppTheme._();

  static ThemeData get base {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.roleBlue,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E5EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E5EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.roleBlue, width: 1.5),
        ),
      ),
    );
  }

  /// Returns the accent color for a given role, used to theme
  /// login/signup screens (green for teacher, purple for principal).
  static Color accentFor(UserRoleTheme role) {
    switch (role) {
      case UserRoleTheme.teacher:
        return AppColors.teacherGreen;
      case UserRoleTheme.principal:
        return AppColors.principalPurple;
    }
  }

  static Color accentLightFor(UserRoleTheme role) {
    switch (role) {
      case UserRoleTheme.teacher:
        return AppColors.teacherGreenLight;
      case UserRoleTheme.principal:
        return AppColors.principalPurpleLight;
    }
  }
}

/// Lightweight enum used purely for theming decisions in the UI layer.
/// (Kept separate from the data-layer UserRole in models/app_user.dart
/// so screens don't need to import Firestore types just to pick a color.)
enum UserRoleTheme { teacher, principal }
