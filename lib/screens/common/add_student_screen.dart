import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/student.dart';
import '../../providers/service_providers.dart';
import '../../theme/app_theme.dart';

/// Add Student screen — also doubles as the Edit Student screen. Pass
/// an existing [student] to pre-fill the form, switch the title/button
/// to "edit" wording, and update instead of create on submit. This
/// keeps the add/edit UI (and its validation) in exactly one place.
class AddStudentScreen extends ConsumerStatefulWidget {
  final Student? student;
  final String? schoolName;

  const AddStudentScreen({super.key, this.student, this.schoolName});

  bool get isEditing => student != null;

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.student?.fullName ?? '',
  );
  late final _gradeController = TextEditingController(
    text: widget.student?.gradeSection ?? '',
  );

  XFile? _pickedPhoto;
  Uint8List? _pickedPhotoBytes;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final photo = await ref.read(storageServiceProvider).pickImage();
    if (photo == null || !mounted) return;
    // Read bytes up front (rather than using dart:io's File, which
    // isn't supported on Flutter Web) so the preview works on every
    // platform via Image.memory/MemoryImage.
    final bytes = await photo.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedPhoto = photo;
      _pickedPhotoBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final student = Student(
        id: widget.student?.id ?? '',
        fullName: _nameController.text.trim(),
        gradeSection: _gradeController.text.trim(),
        schoolName: widget.schoolName ?? widget.student?.schoolName,
      );

      final studentId = widget.isEditing
          ? widget.student!.id
          : await ref.read(flagServiceProvider).createStudent(student);

      if (widget.isEditing) {
        await ref.read(flagServiceProvider).updateStudent(studentId, student);
      }

      if (_pickedPhoto != null) {
        final photoUrl = await ref
            .read(storageServiceProvider)
            .uploadFile('student_photos/$studentId.jpg', _pickedPhoto!);
        await ref
            .read(flagServiceProvider)
            .updateStudentPhoto(studentId, photoUrl);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not ${widget.isEditing ? 'update' : 'add'} student: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingPhotoUrl = widget.student?.photoUrl;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.principalPurple,
        foregroundColor: Colors.white,
        title: Text(widget.isEditing ? 'Edit Student' : 'Add Student'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.principalPurpleLight,
                        backgroundImage: _pickedPhotoBytes != null
                            ? MemoryImage(_pickedPhotoBytes!)
                            : (existingPhotoUrl != null &&
                                  existingPhotoUrl.isNotEmpty)
                            ? NetworkImage(existingPhotoUrl) as ImageProvider
                            : null,
                        child:
                            (_pickedPhotoBytes == null &&
                                (existingPhotoUrl == null ||
                                    existingPhotoUrl.isEmpty))
                            ? const Icon(
                                Icons.person,
                                size: 36,
                                color: AppColors.principalPurple,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.principalPurple,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Full Name',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Habimana Jean Paul',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Grade / Section',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _gradeController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Grade 10 - Science A',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.principalPurple,
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
                      : Text(widget.isEditing ? 'Save Changes' : 'Add Student'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
