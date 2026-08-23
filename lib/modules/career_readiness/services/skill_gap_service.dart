import '../../profile_skills/models/user_skill.dart';
import '../models/career_requirement.dart';

class SkillGapService {
  static const _rank = {'Beginner': 1, 'Intermediate': 2, 'Advanced': 3};

  List<SkillGapResult> compare(
    List<CareerRequirement> requirements,
    List<UserSkill> userSkills,
  ) {
    final owned = {for (final skill in userSkills) skill.skill.id: skill.level};
    return requirements.map((requirement) {
      final current = owned[requirement.skillId];
      final status = current == null
          ? SkillGapStatus.missing
          : (_rank[current] ?? 0) >= (_rank[requirement.requiredLevel] ?? 1)
          ? SkillGapStatus.satisfied
          : SkillGapStatus.insufficient;
      return SkillGapResult(
        requirement: requirement,
        currentLevel: current,
        status: status,
      );
    }).toList();
  }

  double matchPercentage(List<SkillGapResult> results) {
    if (results.isEmpty) return 0;
    return results.where((r) => r.status == SkillGapStatus.satisfied).length /
        results.length *
        100;
  }
}
