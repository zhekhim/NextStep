class RiasecQuestion {
  const RiasecQuestion({
    required this.id,
    required this.dimension,
    required this.activity,
    this.order = 0,
    this.updatedAt,
  });

  final String id;
  final String dimension;
  final String activity;
  final int order;
  final DateTime? updatedAt;

  factory RiasecQuestion.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['question_id'])?.toString().trim() ?? '';
    final dimension = _normalizeDimension(
      (json['dimension_code'] ?? json['dimension'] ?? '').toString(),
    );
    final activity = (json['question_text'] ?? json['activity'] ?? '')
        .toString()
        .trim();
    if (id.isEmpty ||
        !const ['R', 'I', 'A', 'S', 'E', 'C'].contains(dimension) ||
        activity.isEmpty) {
      throw const FormatException('Invalid assessment question data.');
    }
    return RiasecQuestion(
      id: id,
      dimension: dimension,
      activity: activity,
      order: int.tryParse(json['question_order']?.toString() ?? '') ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
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
