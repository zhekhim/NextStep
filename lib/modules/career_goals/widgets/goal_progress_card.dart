import 'package:flutter/material.dart';

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
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
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
                  color: Color(0xFF1A26FF),
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
                    style: const TextStyle(color: Color(0xFFA8A8A8)),
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
            color: const Color(0xFF0007CD),
            backgroundColor: const Color(0xFF2A2A2A),
          ),
          if (!hasMilestones) ...[
            const SizedBox(height: 10),
            const Text(
              'Add development milestones under a required skill to start tracking progress.',
              style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
          ],
        ],
      ),
    );
  }
}
