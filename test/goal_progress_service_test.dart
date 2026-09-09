import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_goals/models/skill_task.dart';
import 'package:untitled/modules/career_goals/services/goal_progress_service.dart';

void main() {
  SkillTask milestone(
    String id, {
    required bool completed,
    DateTime? dueDate,
  }) => SkillTask(
    id: id,
    userId: 'user',
    goalId: 'goal',
    skillId: 'skill',
    taskTitle: 'Milestone $id',
    dueDate: dueDate ?? DateTime(2026, 10, 20),
    isCompleted: completed,
  );

  test('calculates completed count and percentage across the whole goal', () {
    final progress = GoalProgressService().calculate([
      milestone('1', completed: true),
      milestone('2', completed: false),
      milestone('3', completed: true),
    ]);

    expect(progress.completedCount, 2);
    expect(progress.totalCount, 3);
    expect(progress.percentage, closeTo(66.67, 0.01));
    expect(progress.progressValue, closeTo(0.67, 0.01));
  });

  test('returns zero progress when the goal has no milestones', () {
    final progress = GoalProgressService().calculate(const []);

    expect(progress.completedCount, 0);
    expect(progress.totalCount, 0);
    expect(progress.percentage, 0);
    expect(progress.progressValue, 0);
  });

  group('milestone deadline state', () {
    final today = DateTime(2026, 9, 8);

    test('completed takes priority over the due date', () {
      final state = GoalProgressService().deadlineState(
        milestone('1', completed: true, dueDate: DateTime(2026, 9, 1)),
        today: today,
      );

      expect(state, MilestoneDeadlineState.completed);
    });

    test('past incomplete milestone is overdue', () {
      final state = GoalProgressService().deadlineState(
        milestone('1', completed: false, dueDate: DateTime(2026, 9, 7)),
        today: today,
      );

      expect(state, MilestoneDeadlineState.overdue);
    });

    test('due today or within three days is due soon', () {
      final service = GoalProgressService();

      expect(
        service.deadlineState(
          milestone('1', completed: false, dueDate: DateTime(2026, 9, 8)),
          today: today,
        ),
        MilestoneDeadlineState.dueSoon,
      );
      expect(
        service.deadlineState(
          milestone('2', completed: false, dueDate: DateTime(2026, 9, 11)),
          today: today,
        ),
        MilestoneDeadlineState.dueSoon,
      );
    });

    test('incomplete milestone beyond three days is upcoming', () {
      final state = GoalProgressService().deadlineState(
        milestone('1', completed: false, dueDate: DateTime(2026, 9, 12)),
        today: today,
      );

      expect(state, MilestoneDeadlineState.upcoming);
    });
  });

  test('prioritizes actionable milestones and excludes completed ones', () {
    final service = GoalProgressService();
    final today = DateTime(2026, 9, 8);

    final result = service.prioritizedUpcoming([
      milestone('upcoming', completed: false, dueDate: DateTime(2026, 9, 20)),
      milestone('completed', completed: true, dueDate: DateTime(2026, 9, 1)),
      milestone(
        'due-soon-later',
        completed: false,
        dueDate: DateTime(2026, 9, 11),
      ),
      milestone(
        'overdue-later',
        completed: false,
        dueDate: DateTime(2026, 9, 7),
      ),
      milestone(
        'overdue-first',
        completed: false,
        dueDate: DateTime(2026, 9, 5),
      ),
      milestone(
        'due-soon-first',
        completed: false,
        dueDate: DateTime(2026, 9, 8),
      ),
    ], today: today);

    expect(result.map((value) => value.id), [
      'overdue-first',
      'overdue-later',
      'due-soon-first',
      'due-soon-later',
      'upcoming',
    ]);
  });
}
