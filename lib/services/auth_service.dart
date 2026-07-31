import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';

/// Thin wrapper around FirebaseAuth + Firestore
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Signs up a new teacher or principal
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

  // Returns null if the user cancelled or is new
  Future<AppUser?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // cancelled — not an error

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final uid = userCredential.user!.uid;

    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;

    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<AppUser> createGoogleProfile({
    required UserRole role,
    String? employeeId,
    String? schoolName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user found. Please sign in again.',
      );
    }
    final data = {
      'fullName': user.displayName ?? '',
      'email': user.email ?? '',
      'role': role.name,
      'photoUrl': user.photoURL ?? '',
      'employeeId': ?employeeId,
      'schoolName': ?schoolName,
    };
    await _usersRef.doc(user.uid).set(data);
    return AppUser.fromMap(user.uid, data);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Updates the signed-in user's profile photo URL in Firestore
  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await _usersRef.doc(uid).update({'photoUrl': photoUrl});
  }

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
