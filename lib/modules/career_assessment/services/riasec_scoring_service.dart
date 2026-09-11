import '../models/riasec_question.dart';

class RiasecDimensionScore {
  const RiasecDimensionScore({
    required this.dimension,
    required this.average,
    required this.percentage,
    this.totalScore = 0,
    this.questionCount = 0,
    this.enjoyCount = 0,
    this.slightlyEnjoyCount = 0,
    this.dislikeCount = 0,
    this.slightlyDislikeCount = 0,
  });

  final String dimension;
  final double average;
  final double percentage;
  final int totalScore;
  final int questionCount;
  final int enjoyCount;
  final int slightlyEnjoyCount;
  final int dislikeCount;
  final int slightlyDislikeCount;
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
  static const totalQuestions = 48;

  RiasecResult calculate({
    required List<RiasecQuestion> questions,
    required Map<int, int> answers,
  }) {
    validateQuestions(questions);
    for (var index = 0; index < questions.length; index++) {
      final answer = answers[index];
      if (answer == null || answer < 1 || answer > 5) {
        throw ArgumentError(
          'Every assessment question must have an answer from 1 to 5.',
        );
      }
    }

    final scores = dimensions.map((dimension) {
      final values = <int>[
        for (var index = 0; index < questions.length; index++)
          if (questions[index].dimension == dimension) answers[index]!,
      ];
      final totalScore = values.fold(0, (sum, value) => sum + value);
      final average = totalScore / values.length;
      return RiasecDimensionScore(
        dimension: dimension,
        average: average,
        percentage: (average / 5 * 100).clamp(0, 100),
        totalScore: totalScore,
        questionCount: values.length,
        enjoyCount: values.where((value) => value == 5).length,
        slightlyEnjoyCount: values.where((value) => value == 4).length,
        dislikeCount: values.where((value) => value == 1).length,
        slightlyDislikeCount: values.where((value) => value == 2).length,
      );
    }).toList();

    scores.sort((left, right) {
      var comparison = right.totalScore.compareTo(left.totalScore);
      if (comparison != 0) return comparison;

      comparison = right.enjoyCount.compareTo(left.enjoyCount);
      if (comparison != 0) return comparison;

      comparison = right.slightlyEnjoyCount.compareTo(left.slightlyEnjoyCount);
      if (comparison != 0) return comparison;

      comparison = left.dislikeCount.compareTo(right.dislikeCount);
      if (comparison != 0) return comparison;

      comparison = left.slightlyDislikeCount.compareTo(
        right.slightlyDislikeCount,
      );
      if (comparison != 0) return comparison;

      return dimensions
          .indexOf(left.dimension)
          .compareTo(dimensions.indexOf(right.dimension));
    });
    return RiasecResult(scores);
  }

  void validateQuestions(List<RiasecQuestion> questions) {
    if (questions.length != totalQuestions) {
      throw ArgumentError(
        'The assessment must contain exactly $totalQuestions questions.',
      );
    }
    for (final dimension in dimensions) {
      final count = questions
          .where((question) => question.dimension == dimension)
          .length;
      if (count == 0) {
        throw ArgumentError('Dimension $dimension must contain a question.');
      }
    }
  }
}
