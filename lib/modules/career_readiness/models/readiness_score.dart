class ReadinessComponent {
  const ReadinessComponent({
    required this.label,
    required this.score,
    required this.weight,
    required this.description,
  });

  final String label;
  final double score;
  final double weight;
  final String description;

  double get contribution => score * weight;
}

class ReadinessScore {
  const ReadinessScore({
    required this.components,
    required this.strongAreas,
    required this.needsImprovement,
  });

  final List<ReadinessComponent> components;
  final List<String> strongAreas;
  final List<String> needsImprovement;

  double get value => components.fold(
    0,
    (total, component) => total + component.contribution,
  );

  String get status {
    if (value >= 80) return 'Career Ready';
    if (value >= 60) return 'Good Progress';
    if (value >= 40) return 'Building Skills';
    return 'Getting Started';
  }
}
