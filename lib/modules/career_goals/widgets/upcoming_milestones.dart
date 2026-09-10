import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/skill_task.dart';
import '../services/goal_progress_service.dart';

class UpcomingMilestones extends StatelessWidget {
  const UpcomingMilestones({
    required this.milestones,
    required this.progressService,
    this.maximumVisible = 3,
    super.key,
  });

  final List<SkillTask> milestones;
  final GoalProgressService progressService;
  final int maximumVisible;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return const _Container(
        child: Text(
          'No upcoming milestones.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final visible = milestones.take(maximumVisible).toList();
    final remaining = milestones.length - visible.length;
    return _Container(
      child: Column(
        children: [
          for (var index = 0; index < visible.length; index++) ...[
            _MilestoneRow(
              milestone: visible[index],
              state: progressService.deadlineState(visible[index]),
            ),
            if (index < visible.length - 1)
              const Divider(height: 25, color: AppColors.hairline),
          ],
          if (remaining > 0) ...[
            const Divider(height: 25, color: AppColors.hairline),
            Text(
              '$remaining more ${remaining == 1 ? 'milestone' : 'milestones'} shown under the related skills.',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone, required this.state});

  final SkillTask milestone;
  final MilestoneDeadlineState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      MilestoneDeadlineState.overdue => ('Overdue', AppColors.error),
      MilestoneDeadlineState.dueSoon => ('Due Soon', AppColors.warning),
      MilestoneDeadlineState.upcoming => ('Upcoming', AppColors.primaryLight),
      MilestoneDeadlineState.completed => (
        'Completed',
        AppColors.success,
      ),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                milestone.taskTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Due ${_formatDate(milestone.dueDate)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Container extends StatelessWidget {
  const _Container({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.hairline),
    ),
    child: child,
  );
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
