import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../providers/service_providers.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'principal/principal_home_screen.dart';
import 'teacher/teacher_home_screen.dart';

class GoogleRolePickerScreen extends ConsumerStatefulWidget {
  const GoogleRolePickerScreen({super.key});

  @override
  ConsumerState<GoogleRolePickerScreen> createState() =>
      _GoogleRolePickerScreenState();
}

class _GoogleRolePickerScreenState
    extends ConsumerState<GoogleRolePickerScreen> {
  UserRole? _selectedRole;
  final _secondaryController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _secondaryController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selectedRole == null) {
      setState(() => _errorText = 'Please select a role.');
      return;
    }
    if (_secondaryController.text.trim().isEmpty) {
      setState(() => _errorText = _selectedRole == UserRole.teacher
          ? 'Please enter your Employee ID.'
          : 'Please enter your School Name.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final appUser = await ref.read(authServiceProvider).createGoogleProfile(
            role: _selectedRole!,
            employeeId: _selectedRole == UserRole.teacher
                ? _secondaryController.text.trim()
                : null,
            schoolName: _selectedRole == UserRole.principal
                ? _secondaryController.text.trim()
                : null,
          );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => appUser.role == UserRole.teacher
              ? TeacherHomeScreen(user: appUser)
              : PrincipalHomeScreen(user: appUser),
        ),
        (route) => false,
      );
    } catch (e) {
      setState(() => _errorText = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'One more step',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select your role to complete setup.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              _RoleOption(
                label: 'Teacher',
                subtitle: 'Log student issues',
                icon: Icons.person_outline,
                color: AppColors.teacherGreen,
                selected: _selectedRole == UserRole.teacher,
                onTap: () => setState(() => _selectedRole = UserRole.teacher),
              ),
              const SizedBox(height: 12),
              _RoleOption(
                label: 'Principal',
                subtitle: 'Monitor and take action',
                icon: Icons.shield_outlined,
                color: AppColors.principalPurple,
                selected: _selectedRole == UserRole.principal,
                onTap: () => setState(() => _selectedRole = UserRole.principal),
              ),
              const SizedBox(height: 24),
              if (_selectedRole != null) ...[
                Text(
                  _selectedRole == UserRole.teacher
                      ? 'Employee ID'
                      : 'School Name',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _secondaryController,
                  decoration: InputDecoration(
                    hintText: _selectedRole == UserRole.teacher
                        ? 'TCH-2024-001'
                        : 'Groupe Scolaire Kigali',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_errorText != null) ...[
                Text(_errorText!,
                    style: const TextStyle(
                        color: AppColors.urgentRed, fontSize: 13)),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roleBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : const Color(0xFFEDEFF5),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: color)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
