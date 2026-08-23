import 'package:flutter/material.dart';

import '../models/assessment_question.dart';

class AssessmentQuestionCard extends StatelessWidget {
  const AssessmentQuestionCard({
    required this.question,
    required this.selectedValue,
    required this.onSelected,
    super.key,
  });

  static const _answerLabels = <int, String>{
    1: 'Strongly Disagree',
    2: 'Disagree',
    3: 'Neutral',
    4: 'Agree',
    5: 'Strongly Agree',
  };

  final AssessmentQuestion question;
  final int? selectedValue;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.questionText,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            for (final answer in _answerLabels.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onSelected(answer.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedValue == answer.key
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: selectedValue == answer.key
                          ? colorScheme.primary.withValues(alpha: 0.12)
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            answer.key.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(child: Text(answer.value)),
                        if (selectedValue == answer.key)
                          Icon(Icons.check_circle, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
