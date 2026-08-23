import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_readiness/models/career_goal.dart';
import 'package:untitled/modules/career_readiness/models/career_requirement.dart';
import 'package:untitled/modules/career_readiness/services/readiness_calculator.dart';
import 'package:untitled/modules/career_readiness/services/skill_gap_service.dart';

void main() {
  const goal = CareerGoal(
    id: 'goal-1',
    userId: 'user-1',
    career: CareerOption(id: 'career-1', name: 'Data Analyst', category: 'ICT'),
    status: 'Active',
    preferredState: 'Penang',
  );

  test('uses the documented component weights', () {
    const requirement = CareerRequirement(
      skillId: 'skill-1',
      skillName: 'SQL',
      requiredLevel: 'Intermediate',
    );
    const gaps = [
      SkillGapResult(
        requirement: requirement,
        currentLevel: 'Intermediate',
        status: SkillGapStatus.satisfied,
      ),
    ];

    final score = ReadinessCalculator().calculate(
      goal: goal,
      skillGaps: gaps,
      certificationProgress: 50,
      learningProgress: 80,
    );

    expect(score.value, 87);
    expect(score.strongAreas, ['SQL']);
    expect(score.needsImprovement, isEmpty);
  });

  test('clamps progress values to a valid percentage', () {
    final score = ReadinessCalculator().calculate(
      goal: goal,
      skillGaps: const [],
      certificationProgress: 120,
      learningProgress: -10,
    );

    expect(score.components[1].score, 100);
    expect(score.components[2].score, 0);
  });
}
