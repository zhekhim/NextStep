import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/profile_skills/models/user_skill.dart';
import 'package:untitled/modules/profile_skills/services/profile_insights_service.dart';

void main() {
  test('recommends missing skills for the selected career', () {
    final result = ProfileInsightsService().analyse(
      skills: [
        UserSkill(
          id: '1',
          userId: 'user-1',
          skill: const SkillCatalogItem(
            id: 'python',
            name: 'Python',
            category: 'Programming',
          ),
          level: 'Advanced',
        ),
      ],
      targetRoles: const ['Software Engineer'],
    );

    expect(result.market.employmentRate, 94.2);
    expect(result.missingSkills, containsAll(<String>['Java', 'C++', 'SQL']));
  });
}
