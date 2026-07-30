import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';

class AppBottomNavItem {
  final IconData icon;
  final String label;

  const AppBottomNavItem(this.icon, this.label);
}

/// The bottom nav bar shown on dashboard-level screens. The active tab
/// gets a colored pill background — blue on most dashboard screens,
/// green on the teacher's Flagging History screen — matching what's in
/// the Figma prototype rather than forcing one color everywhere.
class AppBottomNav extends ConsumerWidget {
  static const items = [
    AppBottomNavItem(Icons.grid_view_rounded, 'Dashboard'),
    AppBottomNavItem(Icons.people_outline, 'Students'),
    AppBottomNavItem(Icons.favorite_border, 'Intervention'),
    AppBottomNavItem(Icons.person_outline, 'Profile'),
  ];

  final int currentIndex;
  final Color activeColor;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.activeColor = AppColors.navActiveBlue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = index == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: isActive ? Colors.white : AppColors.textMuted,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t(item.label, language),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
