import '../models/riasec_question.dart';

class RiasecDimensionScore {
  const RiasecDimensionScore({
    required this.dimension,
    required this.average,
    required this.percentage,
  });

  final String dimension;
  final double average;
  final double percentage;
}

class RiasecResult {
  const RiasecResult(this.rankedScores);

  final List<RiasecDimensionScore> rankedScores;

  List<RiasecDimensionScore> get strongestDimensions =>
      rankedScores.take(3).toList(growable: false);

  String get code => strongestDimensions.map((score) => score.dimension).join();
}

class RiasecScoringService {
  static const dimensions = ['R', 'I', 'A', 'S', 'E', 'C'];

  RiasecResult calculate({
    required List<RiasecQuestion> questions,
    required Map<int, int> answers,
  }) {
    final scores = dimensions.map((dimension) {
      final values = <int>[
        for (var index = 0; index < questions.length; index++)
          if (questions[index].dimension == dimension) answers[index] ?? 0,
      ];
      final average = values.isEmpty
          ? 0.0
          : values.fold(0, (sum, value) => sum + value) / values.length;
      return RiasecDimensionScore(
        dimension: dimension,
        average: average,
        percentage: average / 5 * 100,
      );
    }).toList();

    scores.sort((left, right) {
      final scoreComparison = right.percentage.compareTo(left.percentage);
      if (scoreComparison != 0) return scoreComparison;
      return dimensions
          .indexOf(left.dimension)
          .compareTo(dimensions.indexOf(right.dimension));
    });
    return RiasecResult(scores);
  }
}
