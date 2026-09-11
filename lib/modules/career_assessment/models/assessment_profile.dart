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

  List<String> get rankedDimensions {
    final remaining =
        RiasecScoringService.dimensions
            .where((dimension) => !riasecCode.contains(dimension))
            .toList()
          ..sort((left, right) {
            final comparison = (percentages[right] ?? 0).compareTo(
              percentages[left] ?? 0,
            );
            return comparison != 0
                ? comparison
                : RiasecScoringService.dimensions
                      .indexOf(left)
                      .compareTo(
                        RiasecScoringService.dimensions.indexOf(right),
                      );
          });
    return [...riasecCode.split(''), ...remaining];
  }

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
      if (!score.percentage.isFinite ||
          score.percentage < 0 ||
          score.percentage > 100) {
        throw ArgumentError('Invalid assessment percentage.');
      }
      fields[entry.value] = score.percentage.round();
    }
    return fields;
  }

  factory AssessmentProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    final code = json['riasec_code']?.toString().trim().toUpperCase() ?? '';
    final percentages = <String, double>{};
    for (final entry in columns.entries) {
      final value = double.tryParse(json[entry.value]?.toString() ?? '');
      if (value == null || !value.isFinite || value < 0 || value > 100) {
        throw const FormatException('Invalid assessment history data.');
      }
      percentages[entry.key] = value;
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
    final scoresByDimension = {
      for (final dimension in RiasecScoringService.dimensions)
        dimension: RiasecDimensionScore(
          dimension: dimension,
          average: (percentages[dimension] ?? 0) / 20,
          percentage: percentages[dimension] ?? 0,
        ),
    };
    return RiasecResult(
      rankedDimensions
          .map((dimension) => scoresByDimension[dimension]!)
          .toList(growable: false),
    );
  }
}
