class RiasecQuestion {
  const RiasecQuestion({
    required this.id,
    required this.dimension,
    required this.activity,
  });

  final String id;
  final String dimension;
  final String activity;

  factory RiasecQuestion.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['question_id'])?.toString().trim() ?? '';
    final dimension = _normalizeDimension(
      (json['dimension_code'] ?? json['dimension'] ?? '').toString(),
    );
    final activity = (json['question_text'] ?? json['activity'] ?? '')
        .toString()
        .trim();
    if (id.isEmpty || !const ['R', 'I', 'A', 'S', 'E', 'C'].contains(dimension) ||
        activity.isEmpty) {
      throw const FormatException('Invalid assessment question data.');
    }
    return RiasecQuestion(id: id, dimension: dimension, activity: activity);
  }

  static String _normalizeDimension(String value) {
    const dimensionCodes = {
      'R': 'R',
      'REALISTIC': 'R',
      'I': 'I',
      'INVESTIGATIVE': 'I',
      'A': 'A',
      'ARTISTIC': 'A',
      'S': 'S',
      'SOCIAL': 'S',
      'E': 'E',
      'ENTERPRISING': 'E',
      'C': 'C',
      'CONVENTIONAL': 'C',
    };
    return dimensionCodes[value.trim().toUpperCase()] ?? '';
  }
}
