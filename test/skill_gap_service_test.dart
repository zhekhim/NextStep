import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_goals/models/career_requirement.dart';
import 'package:untitled/modules/career_goals/services/skill_gap_service.dart';
import 'package:untitled/modules/profile_skills/models/user_skill.dart';

void main() {
  test('classifies satisfied, insufficient, and missing skills', () {
    const python = SkillCatalogItem(
      id: 'python',
      name: 'Python',
      category: 'Programming',
    );
    const sql = SkillCatalogItem(id: 'sql', name: 'SQL', category: 'Database');
    const requirements = [
      CareerRequirement(
        skillId: 'python',
        skillName: 'Python',
        requiredLevel: 'Intermediate',
      ),
      CareerRequirement(
        skillId: 'sql',
        skillName: 'SQL',
        requiredLevel: 'Advanced',
      ),
      CareerRequirement(
        skillId: 'statistics',
        skillName: 'Statistics',
        requiredLevel: 'Beginner',
      ),
    ];
    const userSkills = [
      UserSkill(id: '1', userId: 'user', skill: python, level: 'Advanced'),
      UserSkill(id: '2', userId: 'user', skill: sql, level: 'Intermediate'),
    ];

    final service = SkillGapService();
    final results = service.compare(requirements, userSkills);

    expect(results.map((result) => result.status), [
      SkillGapStatus.satisfied,
      SkillGapStatus.insufficient,
      SkillGapStatus.missing,
    ]);
    expect(service.matchPercentage(results), closeTo(33.33, 0.01));
  });
}
