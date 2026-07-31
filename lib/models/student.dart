class Student {
  final String id;
  final String fullName;
  final String gradeSection;
  final String? photoUrl;
  final String? schoolName;

  const Student({
    required this.id,
    required this.fullName,
    required this.gradeSection,
    this.photoUrl,
    this.schoolName,
  });

  factory Student.fromMap(String id, Map<String, dynamic> map) {
    return Student(
      id: id,
      fullName: map['fullName'] as String? ?? 'Unknown',
      gradeSection: map['gradeSection'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      schoolName: map['schoolName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'gradeSection': gradeSection,
    'photoUrl': ?photoUrl,
    'schoolName': ?schoolName,
  };
}
