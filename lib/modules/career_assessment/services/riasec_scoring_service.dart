import '../models/riasec_question.dart';

class RiasecDimensionScore {
  const RiasecDimensionScore({
    required this.dimension,
    required this.total,
    required this.enjoyCount,
    required this.slightlyEnjoyCount,
  });

  final String dimension;
  final int total;
  final int enjoyCount;
  final int slightlyEnjoyCount;

  bool hasSameRankAs(RiasecDimensionScore other) {
    return total == other.total &&
        enjoyCount == other.enjoyCount &&
        slightlyEnjoyCount == other.slightlyEnjoyCount;
  }
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
      return RiasecDimensionScore(
        dimension: dimension,
        total: values.fold(0, (sum, value) => sum + value),
        enjoyCount: values.where((value) => value == 5).length,
        slightlyEnjoyCount: values.where((value) => value == 4).length,
      );
    }).toList();

    scores.sort((left, right) {
      final totalComparison = right.total.compareTo(left.total);
      if (totalComparison != 0) return totalComparison;
      final enjoyComparison = right.enjoyCount.compareTo(left.enjoyCount);
      if (enjoyComparison != 0) return enjoyComparison;
      final slightlyEnjoyComparison = right.slightlyEnjoyCount.compareTo(
        left.slightlyEnjoyCount,
      );
      if (slightlyEnjoyComparison != 0) return slightlyEnjoyComparison;
      return dimensions
          .indexOf(left.dimension)
          .compareTo(dimensions.indexOf(right.dimension));
    });
    return RiasecResult(scores);
  }
}
