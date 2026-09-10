class CareerAssessmentProfile {
  const CareerAssessmentProfile({
    required this.careerId,
    required this.dimensionValues,
  });

  final String careerId;
  final Map<String, double> dimensionValues;

  factory CareerAssessmentProfile.fromJson(Map<String, dynamic> json) {
    final careerId = json['career_id']?.toString().trim() ?? '';
    final values = <String, double>{};
    const keys = {
      'R': ['r', 'realistic', 'realistic_score'],
      'I': ['i', 'investigative', 'investigative_score'],
      'A': ['a', 'artistic', 'artistic_score'],
      'S': ['s', 'social', 'social_score'],
      'E': ['e', 'enterprising', 'enterprising_score'],
      'C': ['c', 'conventional', 'conventional_score'],
    };
    for (final entry in keys.entries) {
      final value = _readValue(json, entry.value);
      if (value == null || value < 1 || value > 5) {
        throw const FormatException('Invalid career assessment profile data.');
      }
      values[entry.key] = value;
    }
    if (careerId.isEmpty) {
      throw const FormatException('Invalid career assessment profile data.');
    }
    return CareerAssessmentProfile(
      careerId: careerId,
      dimensionValues: values,
    );
  }

  static double? _readValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = double.tryParse(json[key]?.toString() ?? '');
      if (value != null) return value;
    }
    return null;
  }
}
