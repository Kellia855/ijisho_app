enum UserRole { teacher, principal }

extension UserRoleX on UserRole {
  String get label => switch (this) {
    UserRole.teacher => 'Teacher',
    UserRole.principal => 'Principal',
  };

  String get firestoreValue => switch (this) {
    UserRole.teacher => 'teacher',
    UserRole.principal => 'principal',
  };

  static UserRole fromFirestore(String value) => switch (value) {
    'principal' => UserRole.principal,
    _ => UserRole.teacher,
  };
}

/// Represents a signed-up IJISHO user, stored in the `users` collection
/// in Firestore, keyed by Firebase Auth uid.
class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final UserRole role;

  final String? employeeId;
  final String? schoolName; // both teacher and principal

  final String? photoUrl;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.employeeId,
    this.schoolName,
    this.photoUrl,
  });

  AppUser copyWith({String? photoUrl}) {
    return AppUser(
      uid: uid,
      fullName: fullName,
      email: email,
      role: role,
      employeeId: employeeId,
      schoolName: schoolName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role.firestoreValue,
      'employeeId': ?employeeId,
      'schoolName': ?schoolName,
      'photoUrl': ?photoUrl,
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRoleX.fromFirestore(map['role'] as String? ?? 'teacher'),
      employeeId: map['employeeId'] as String?,
      schoolName: map['schoolName'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }
}
