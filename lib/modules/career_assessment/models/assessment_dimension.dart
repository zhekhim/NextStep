class AssessmentDimension {
  const AssessmentDimension({
    required this.code,
    required this.name,
    required this.description,
    required this.characteristics,
  });

  final String code;
  final String name;
  final String description;
  final String characteristics;

  factory AssessmentDimension.fromJson(Map<String, dynamic> json) {
    final code =
        (json['dimension_code'] ?? json['dimension'] ?? json['code'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
    final storedName = (json['dimension_name'] ?? json['name'] ?? '')
        .toString()
        .trim();
    final name = storedName.isNotEmpty ? storedName : _nameForCode(code);
    final description = (json['description'] ?? '').toString().trim();
    final characteristics = (json['characteristics'] ?? '').toString().trim();
    if (code.isEmpty || name.isEmpty || description.isEmpty) {
      throw const FormatException('Invalid assessment dimension data.');
    }
    return AssessmentDimension(
      code: code,
      name: name,
      description: description,
      characteristics: characteristics,
    );
  }

  static String _nameForCode(String code) => switch (code) {
    'R' => 'Realistic',
    'I' => 'Investigative',
    'A' => 'Artistic',
    'S' => 'Social',
    'E' => 'Enterprising',
    'C' => 'Conventional',
    _ => '',
  };
}
