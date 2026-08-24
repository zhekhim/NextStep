class CareerRequirement {
  const CareerRequirement({
    required this.skillId,
    required this.skillName,
    required this.requiredLevel,
  });
  final String skillId;
  final String skillName;
  final String requiredLevel;
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
