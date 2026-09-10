class RiasecAssessmentProfile {
  const RiasecAssessmentProfile({
    required this.scores,
    required this.code,
  });

  final Map<String, int> scores;
  final String code;

  List<String> get rankedDimensions {
    final dimensions = ['R', 'I', 'A', 'S', 'E', 'C'];
    final remaining = dimensions.where((item) => !code.contains(item)).toList()
      ..sort((left, right) {
        final comparison = (scores[right] ?? 0).compareTo(scores[left] ?? 0);
        return comparison != 0
            ? comparison
            : dimensions.indexOf(left).compareTo(dimensions.indexOf(right));
      });
    return [...code.split(''), ...remaining];
  }
}
