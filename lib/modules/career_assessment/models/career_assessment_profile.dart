import '../../career_intelligence/models/career.dart';

class CareerAssessmentProfile {
  const CareerAssessmentProfile({
    required this.id,
    required this.careerId,
    required this.career,
    required this.technical,
    required this.analytical,
    required this.creative,
    required this.business,
    required this.leadership,
    required this.research,
  });

  final String id;
  final String careerId;
  final Career career;
  final double technical;
  final double analytical;
  final double creative;
  final double business;
  final double leadership;
  final double research;

  factory CareerAssessmentProfile.fromJson(Map<String, dynamic> json) {
    final relatedCareer = json['careers'];
    final careerJson = relatedCareer is List
        ? Map<String, dynamic>.from(relatedCareer.single as Map)
        : Map<String, dynamic>.from(relatedCareer as Map);

    return CareerAssessmentProfile(
      id: json['id'].toString(),
      careerId: json['career_id'].toString(),
      career: Career.fromJson(careerJson),
      technical: _toDouble(json['technical']),
      analytical: _toDouble(json['analytical']),
      creative: _toDouble(json['creative']),
      business: _toDouble(json['business']),
      leadership: _toDouble(json['leadership']),
      research: _toDouble(json['research']),
    );
  }

  double valueForDimension(String dimension) {
    return switch (dimension) {
      'Technical' => technical,
      'Analytical' => analytical,
      'Creative' => creative,
      'Business' => business,
      'Leadership' => leadership,
      'Research' => research,
      _ => throw ArgumentError.value(dimension, 'dimension'),
    };
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.parse(value.toString());
  }
}
