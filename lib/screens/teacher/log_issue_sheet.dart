import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/flag.dart';
import '../../models/student.dart';
import '../../providers/service_providers.dart';
import '../../providers/stream_providers.dart';
import '../../theme/app_theme.dart';

/// Opened when a teacher taps one of the Report Issues cards (category
/// pre-selected) or the floating + button (category chosen in the sheet).
/// Matches the flow described in the design doc: select student → pick
/// issue type → add a short note → submit.
class LogIssueSheet extends ConsumerStatefulWidget {
  final String teacherUid;
  final String teacherName;
  final Student? preselectedStudent;
  final FlagCategory? preselectedCategory;

  const LogIssueSheet({
    super.key,
    required this.teacherUid,
    required this.teacherName,
    this.preselectedStudent,
    this.preselectedCategory,
  });

  static Future<void> show(
    BuildContext context, {
    required String teacherUid,
    required String teacherName,
    Student? preselectedStudent,
    FlagCategory? preselectedCategory,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogIssueSheet(
        teacherUid: teacherUid,
        teacherName: teacherName,
        preselectedStudent: preselectedStudent,
        preselectedCategory: preselectedCategory,
      ),
    );
  }

  @override
  ConsumerState<LogIssueSheet> createState() => _LogIssueSheetState();
}

class _LogIssueSheetState extends ConsumerState<LogIssueSheet> {
  static const _selectableCategories = [
    FlagCategory.absent,
    FlagCategory.noUniform,
    FlagCategory.noLunch,
    FlagCategory.struggling,
  ];

  final _noteController = TextEditingController();

  Student? _selectedStudent;
  FlagCategory? _selectedCategory;
  FlagSeverity _selectedSeverity = FlagSeverity.warning;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.preselectedStudent;
    _selectedCategory = widget.preselectedCategory;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedStudent == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a student and an issue type.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(flagServiceProvider).createFlag(
            StudentFlag(
              id: '',
              studentName: _selectedStudent!.fullName,
              gradeSection: _selectedStudent!.gradeSection,
              category: _selectedCategory!,
              severity: _selectedSeverity,
              status: FlagStatus.reported,
              note: _noteController.text.trim(),
              teacherName: widget.teacherName,
              teacherUid: widget.teacherUid,
              createdAt: DateTime.now(),
              studentPhotoUrl: _selectedStudent!.photoUrl,
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E5EC),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Log Student Issue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Select Student', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              studentsAsync.when(
                data: (students) => DropdownButtonFormField<Student>(
                  initialValue: _selectedStudent,
                  isExpanded: true,
                  hint: const Text('-- Select Student --'),
                  items: students
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text('${s.fullName} (${s.gradeSection})'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedStudent = value),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Could not load students: $e'),
              ),
              const SizedBox(height: 16),
              const Text('Issue Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _selectableCategories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category.label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = category),
                    selectedColor: category.accent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: category.bg,
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('How urgent is this?', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: FlagSeverity.values.map((severity) {
                  final isSelected = _selectedSeverity == severity;
                  return ChoiceChip(
                    label: Text(severity.label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedSeverity = severity),
                    selectedColor: severity.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: severity.color.withValues(alpha: 0.12),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Observation Note', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'What did you observe? (optional)',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teacherGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit Flag'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
