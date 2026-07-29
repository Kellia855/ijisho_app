import 'package:flutter/material.dart';

class PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const PillBadge({
    super.key,
    required this.label,
    required this.color,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}
