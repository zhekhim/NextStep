class Career {
  const Career({
    required this.id,
    required this.careerName,
    required this.category,
    required this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String careerName;
  final String category;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Career.fromJson(Map<String, dynamic> json) {
    return Career(
      id: json['id'].toString(),
      careerName: json['career_name'].toString(),
      category: json['category'].toString(),
      description: json['description'].toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    return value == null ? null : DateTime.tryParse(value.toString());
  }
}
