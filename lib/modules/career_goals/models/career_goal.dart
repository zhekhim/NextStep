class CareerOption {
  const CareerOption({
    required this.id,
    required this.name,
    required this.category,
    this.riasecCode,
  });
  final String id;
  final String name;
  final String category;
  final String? riasecCode;
  factory CareerOption.fromMap(Map<String, dynamic> map) => CareerOption(
    id: map['id'].toString(),
    name: map['career_name'].toString(),
    category: map['category'].toString(),
    riasecCode: map['riasec_code']?.toString(),
  );
}

class CareerGoal {
  const CareerGoal({
    required this.id,
    required this.userId,
    required this.career,
    this.preferredState,
    this.targetGraduationYear,
    this.expectedSalary,
  });
  final String id;
  final String userId;
  final CareerOption career;
  final String? preferredState;
  final int? targetGraduationYear;
  final double? expectedSalary;
}
