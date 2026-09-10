import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../services/goal_progress_service.dart';

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({required this.progress, super.key});

  final GoalProgress progress;

  @override
  Widget build(BuildContext context) {
    final hasMilestones = progress.totalCount > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${progress.percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    hasMilestones
                        ? '${progress.completedCount} / ${progress.totalCount} milestones completed'
                        : 'No milestones added yet',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progress.progressValue,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: progress.progressValue == 1
                ? AppColors.success
                : AppColors.primary,
            backgroundColor: AppColors.hairlineStrong,
          ),
          if (!hasMilestones) ...[
            const SizedBox(height: 10),
            const Text(
              'Add development milestones under a required skill to start tracking progress.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
