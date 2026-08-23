import '../models/assessment_answer.dart';
import '../models/assessment_result.dart';

class AssessmentScoringService {
  static const dimensions = <String>[
    'Technical',
    'Analytical',
    'Creative',
    'Business',
    'Leadership',
    'Research',
  ];

  AssessmentResult calculateScores(Iterable<AssessmentAnswer> answers) {
    final valuesByDimension = {
      for (final dimension in dimensions) dimension: <int>[],
    };

    for (final answer in answers) {
      final values = valuesByDimension[answer.dimension];
      if (values != null) values.add(answer.selectedValue);
    }

    final scores = <String, double>{};
    for (final dimension in dimensions) {
      final values = valuesByDimension[dimension]!;
      if (values.isEmpty) {
        scores[dimension] = 0;
        continue;
      }

      final total = values.fold<int>(0, (sum, value) => sum + value);
      final average = total / values.length;
      scores[dimension] = average / 5 * 100;
    }

    return AssessmentResult(scores);
  }
}
