class CareerRequirement {
  const CareerRequirement({
    required this.skillId,
    required this.skillName,
    required this.requiredLevel,
  });
  final String skillId;
  final String skillName;
  final String requiredLevel;

  factory CareerRequirement.fromJson(Map<String, dynamic> json) =>
      CareerRequirement(
        skillId: json['skill_id'].toString(),
        skillName: json['skill_name'].toString(),
        requiredLevel: json['required_level'].toString(),
      );

  Map<String, Object?> toCacheRow(String careerId) => {
    'career_id': careerId,
    'skill_id': skillId,
    'skill_name': skillName,
    'required_level': requiredLevel,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };
}

enum SkillGapStatus { satisfied, insufficient, missing }

class SkillGapResult {
  const SkillGapResult({
    required this.requirement,
    required this.currentLevel,
    required this.status,
  });
  final CareerRequirement requirement;
  final String? currentLevel;
  final SkillGapStatus status;
}
