import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_goals/models/skill_task.dart';
import 'package:untitled/modules/career_goals/widgets/skill_task_list.dart';

void main() {
  test('suggested milestone fields are read from Supabase data', () {
    final task = SkillTask.fromJson({
      'id': 'task-id',
      'user_id': 'user-id',
      'goal_id': 'goal-id',
      'skill_id': 'skill-id',
      'template_id': 'template-id',
      'task_title': 'Build a small project',
      'description': 'Apply the skill to a realistic problem.',
      'completion_evidence': 'A working project and short explanation.',
      'due_date': '2026-09-20',
      'is_completed': false,
    });

    expect(task.templateId, 'template-id');
    expect(task.description, 'Apply the skill to a realistic problem.');
    expect(
      task.completionEvidence,
      'A working project and short explanation.',
    );
  });

  testWidgets('milestone list accepts the current goal and skill', (
    tester,
  ) async {
    const list = SkillTaskList(
      goalId: 'goal-id',
      skillId: 'skill-id',
      careerGoalTitle: 'Software Developer',
      currentLevel: 'Beginner',
      requiredLevel: 'Advanced',
    );

    expect(list.goalId, 'goal-id');
    expect(list.skillId, 'skill-id');
  });
}
