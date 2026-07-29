import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// Thin wrapper around FirebaseAuth + Firestore so screens never talk
/// to Firebase directly. Keeps auth logic in one testable place.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Signs up a new teacher or principal, then writes their profile
  /// (including role-specific fields) to Firestore under `users/{uid}`.
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? employeeId,
    String? schoolName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final appUser = AppUser(
      uid: uid,
      fullName: fullName.trim(),
      email: email.trim(),
      role: role,
      employeeId: employeeId?.trim(),
      schoolName: schoolName?.trim(),
    );

    await _usersRef.doc(uid).set(appUser.toMap());
    await credential.user!.updateDisplayName(fullName.trim());

    return appUser;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final doc = await _usersRef.doc(credential.user!.uid).get();
    if (!doc.exists) {
      throw FirebaseAuthException(
        code: 'user-profile-missing',
        message: 'No IJISHO profile found for this account.',
      );
    }

    return AppUser.fromMap(credential.user!.uid, doc.data()!);
  }

  Future<void> signOut() => _auth.signOut();

  /// Updates the signed-in user's profile photo URL in Firestore, after
  /// StorageService has already uploaded the image.
  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await _usersRef.doc(uid).update({'photoUrl': photoUrl});
  }

  /// Maps FirebaseAuthException codes to short, user-facing messages
  /// so screens can show something friendlier than a raw error code.
  static String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'user-profile-missing':
          return error.message ?? 'Account profile not found.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
