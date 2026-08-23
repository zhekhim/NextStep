class AssessmentResult {
  AssessmentResult(Map<String, double> dimensionScores)
    : dimensionScores = Map.unmodifiable(dimensionScores);

  final Map<String, double> dimensionScores;

  List<MapEntry<String, double>> get rankedScores {
    final scores = dimensionScores.entries.toList()
      ..sort((a, b) {
        final scoreComparison = b.value.compareTo(a.value);
        return scoreComparison != 0 ? scoreComparison : a.key.compareTo(b.key);
      });
    return scores;
  }

  List<String> get strongestAreas {
    return rankedScores.take(3).map((entry) => entry.key).toList();
  }
}
