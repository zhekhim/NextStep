class EmploymentStat {
  const EmploymentStat({
    required this.career,
    required this.employmentRate,
    required this.unemploymentRate,
    required this.requiredSkills,
    required this.outlook,
  });

  final String career;
  final double employmentRate;
  final double unemploymentRate;
  final List<String> requiredSkills;
  final String outlook;

  factory EmploymentStat.fromJson(Map<String, dynamic> json) {
    return EmploymentStat(
      career: json['career'].toString(),
      employmentRate: _number(json['employment_rate']),
      unemploymentRate: _number(json['unemployment_rate']),
      requiredSkills: (json['required_skills'] as List<dynamic>? ?? const [])
          .map((skill) => skill.toString())
          .toList(growable: false),
      outlook: json['outlook'].toString(),
    );
  }

  static double _number(Object? value) {
    return value is num ? value.toDouble() : double.parse(value.toString());
  }

  String get demandLabel {
    if (employmentRate >= 90) return 'High demand';
    if (employmentRate >= 80) return 'Stable demand';
    return 'Monitor market';
  }
}
