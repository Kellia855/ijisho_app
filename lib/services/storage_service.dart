import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Handles picking an image from the device and uploading it to
/// Firebase Storage, returning a public download URL to store on the
/// user's or student's Firestore document.
///
/// Deliberately avoids `dart:io`'s `File` class: it isn't supported on
/// Flutter Web (calling it throws at runtime), which is what caused the
/// "Assertion failed: js_primitives.dart" crash when picking a photo in
/// a browser. Reading the picked image as bytes and uploading with
/// `putData` works identically on web, mobile, and desktop.
class StorageService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  StorageService({FirebaseStorage? storage, ImagePicker? picker})
      : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  /// Opens the gallery and returns the picked file without uploading —
  /// use this when you need to show a local preview before a Storage
  /// path is known (e.g. Add Student, where the path depends on a
  /// Firestore doc id that doesn't exist until the form is submitted).
  Future<XFile?> pickImage() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
  }

  Future<String> uploadFile(String storagePath, XFile file) async {
    final bytes = await file.readAsBytes();
    final ref = _storage.ref(storagePath);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Convenience for the common case: pick then immediately upload to a
  /// path that's already known (e.g. a signed-in user's own uid).
  /// Returns null if the user cancelled the picker.
  Future<String?> pickAndUpload(String storagePath) async {
    final picked = await pickImage();
    if (picked == null) return null;
    return uploadFile(storagePath, picked);
  }
}
