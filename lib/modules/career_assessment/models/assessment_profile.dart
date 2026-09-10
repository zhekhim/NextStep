import '../services/riasec_scoring_service.dart';

class AssessmentProfile {
  const AssessmentProfile({
    required this.id,
    required this.createdAt,
    required this.riasecCode,
    required this.percentages,
  });

  final String id;
  final DateTime createdAt;
  final String riasecCode;
  final Map<String, double> percentages;

  static const columns = {
    'R': 'realistic',
    'I': 'investigative',
    'A': 'artistic',
    'S': 'social',
    'E': 'enterprising',
    'C': 'conventional',
  };

  static Map<String, int> scoreFields(RiasecResult result) {
    final fields = <String, int>{};
    for (final entry in columns.entries) {
      final score = result.rankedScores.singleWhere(
        (score) => score.dimension == entry.key,
      );
      if (score.totalScore < 1 || score.totalScore > 240) {
        throw ArgumentError('Invalid assessment total.');
      }
      fields[entry.value] = score.totalScore;
    }
    return fields;
  }

  factory AssessmentProfile.fromJson(
    Map<String, dynamic> json, {
    Map<String, int> questionCounts = const {},
  }) {
    final id = json['id']?.toString().trim() ?? '';
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    final code = json['riasec_code']?.toString().trim().toUpperCase() ?? '';
    final percentages = <String, double>{};
    for (final entry in columns.entries) {
      final value = double.tryParse(json[entry.value]?.toString() ?? '');
      final count = questionCounts[entry.key] ?? 8;
      if (value == null ||
          !value.isFinite ||
          count < 1 ||
          value < count ||
          value > count * 5) {
        throw const FormatException('Invalid assessment history data.');
      }
      percentages[entry.key] = (value / count - 1) / 4 * 100;
    }
    if (id.isEmpty || createdAt == null || code.length != 3) {
      throw const FormatException('Invalid assessment history data.');
    }
    return AssessmentProfile(
      id: id,
      createdAt: createdAt,
      riasecCode: code,
      percentages: percentages,
    );
  }

  RiasecResult toResult() {
    final scores = RiasecScoringService.dimensions
        .map(
          (dimension) => RiasecDimensionScore(
            dimension: dimension,
            average: 1 + (percentages[dimension] ?? 0) / 25,
            percentage: percentages[dimension] ?? 0,
          ),
        )
        .toList();
    scores.sort((left, right) => right.percentage.compareTo(left.percentage));
    return RiasecResult(scores);
  }
}
