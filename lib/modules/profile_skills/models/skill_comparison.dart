import '../../career_intelligence/models/career.dart';
import '../../career_intelligence/models/career_skill.dart';
import 'user_skill.dart';

class SkillComparisonItem {
  const SkillComparisonItem({
    required this.requirement,
    required this.currentLevel,
  });

  final CareerSkill requirement;
  final String? currentLevel;

  static const _levels = {'Beginner': 1, 'Intermediate': 2, 'Advanced': 3};

  bool get isMissing => currentLevel == null;

  bool get isInsufficient {
    if (currentLevel == null) return false;
    return (_levels[currentLevel] ?? 0) <
        (_levels[requirement.requiredLevel] ?? 1);
  }

  bool get isSatisfied => !isMissing && !isInsufficient;
}

class SkillComparison {
  const SkillComparison({
    required this.career,
    required this.items,
    required this.userSkills,
  });

  final Career career;
  final List<SkillComparisonItem> items;
  final List<UserSkill> userSkills;

  List<String> get missingSkills => items
      .where((item) => item.isMissing || item.isInsufficient)
      .map((item) => item.requirement.skillName)
      .toList(growable: false);

  int get satisfiedCount => items.where((item) => item.isSatisfied).length;

  double get matchPercentage {
    if (items.isEmpty) return 0;
    return satisfiedCount / items.length * 100;
  }
}
