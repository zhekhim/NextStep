import '../models/skill_task.dart';

enum MilestoneDeadlineState { completed, overdue, dueSoon, upcoming }

class GoalProgress {
  const GoalProgress({required this.completedCount, required this.totalCount});

  final int completedCount;
  final int totalCount;

  double get percentage =>
      totalCount == 0 ? 0 : completedCount / totalCount * 100;

  double get progressValue => totalCount == 0 ? 0 : completedCount / totalCount;
}

class GoalProgressService {
  static const dueSoonDays = 3;

  GoalProgress calculate(Iterable<SkillTask> milestones) {
    final values = milestones.toList();
    return GoalProgress(
      completedCount: values.where((milestone) => milestone.isCompleted).length,
      totalCount: values.length,
    );
  }

  MilestoneDeadlineState deadlineState(SkillTask milestone, {DateTime? today}) {
    if (milestone.isCompleted) return MilestoneDeadlineState.completed;

    final currentDate = _dateOnly(today ?? DateTime.now());
    final dueDate = _dateOnly(milestone.dueDate);
    if (dueDate.isBefore(currentDate)) {
      return MilestoneDeadlineState.overdue;
    }
    if (dueDate.difference(currentDate).inDays <= dueSoonDays) {
      return MilestoneDeadlineState.dueSoon;
    }
    return MilestoneDeadlineState.upcoming;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
