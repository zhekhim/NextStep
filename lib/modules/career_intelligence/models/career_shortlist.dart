import 'career.dart';

class CareerShortlist {
  const CareerShortlist({
    required this.id,
    required this.userId,
    required this.career,
    required this.createdAt,
    required this.updatedAt,
    this.priority,
    this.notes,
  });

  static const priorities = ['High', 'Medium', 'Low'];

  final String id;
  final String userId;
  final Career career;
  final String? priority;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CareerShortlist.fromJson(Map<String, dynamic> json) {
    final careerJson = json['careers'];
    if (careerJson is! Map) {
      throw const FormatException('Shortlist career data is missing.');
    }
    final careerMap = Map<String, dynamic>.from(careerJson);
    for (final key in ['id', 'career_name', 'category', 'description']) {
      _requiredString(careerMap, key);
    }
    return CareerShortlist(
      id: _requiredString(json, 'id'),
      userId: _requiredString(json, 'user_id'),
      career: Career.fromJson(careerMap),
      priority: validatePriority(json['priority'] as String?),
      notes: normalizeNotes(json['notes'] as String?),
      createdAt: _requiredDate(json, 'created_at'),
      updatedAt: _requiredDate(json, 'updated_at'),
    );
  }

  static String? validatePriority(String? value) {
    if (value != null && !priorities.contains(value)) {
      throw ArgumentError.value(value, 'priority', 'Select a valid priority.');
    }
    return value;
  }

  static String? normalizeNotes(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized.length > 500) {
      throw ArgumentError.value(
        value,
        'notes',
        'Notes cannot exceed 500 characters.',
      );
    }
    return normalized;
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value.toString().trim().isEmpty) {
      throw FormatException('Required field $key is missing.');
    }
    return value.toString();
  }

  static DateTime _requiredDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    final date = value == null ? null : DateTime.tryParse(value.toString());
    if (date == null) throw FormatException('Required field $key is invalid.');
    return date;
  }
}
