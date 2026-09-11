import '../../career_intelligence/models/career.dart';
import '../../career_intelligence/repositories/career_repository.dart';
import '../models/skill_comparison.dart';
import '../repositories/skill_repository.dart';

class SkillComparisonService {
  SkillComparisonService({
    CareerRepository? careerRepository,
    SkillRepository? skillRepository,
  }) : _careerRepository = careerRepository ?? CareerRepository(),
       _skillRepository = skillRepository ?? SkillRepository();

  final CareerRepository _careerRepository;
  final SkillRepository _skillRepository;

  Future<SkillComparison> compareForCareer(Career career) async {
    final requirements = await _careerRepository.getSkillsForCareer(career.id);
    final userSkills = await _skillRepository.getUserSkills();
    final levels = {
      for (final skill in userSkills) skill.skill.id: skill.level,
    };
    final items = requirements
        .map(
          (requirement) => SkillComparisonItem(
            requirement: requirement,
            currentLevel: levels[requirement.skillId],
          ),
        )
        .toList(growable: false);
    return SkillComparison(
      career: career,
      items: items,
      userSkills: userSkills,
    );
  }

  Future<SkillComparison?> compareForRole(String role) async {
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole.isEmpty) return null;
    final careers = await _careerRepository.getCareers();
    final matches = careers.where(
      (career) => career.careerName.toLowerCase() == normalizedRole,
    );
    if (matches.isEmpty) return null;
    return compareForCareer(matches.first);
  }
}
