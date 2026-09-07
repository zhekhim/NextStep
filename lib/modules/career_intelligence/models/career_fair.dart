class CareerFair {
  const CareerFair({
    required this.id,
    required this.title,
    required this.organiser,
    required this.description,
    required this.eventDate,
    required this.venue,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    this.startTime,
    this.endTime,
    this.latitude,
    this.longitude,
    this.registrationUrl,
    this.sourceUrl,
  });

  final String id;
  final String title;
  final String organiser;
  final String description;
  final DateTime eventDate;
  final Duration? startTime;
  final Duration? endTime;
  final String venue;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? registrationUrl;
  final String? sourceUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get hasUsableLocation => hasCoordinates || address.trim().isNotEmpty;

  factory CareerFair.fromJson(Map<String, dynamic> json) {
    final latitude = _optionalDouble(json['latitude'], 'latitude');
    final longitude = _optionalDouble(json['longitude'], 'longitude');
    if ((latitude == null) != (longitude == null)) {
      throw const FormatException(
        'Career fair coordinates must be a complete pair.',
      );
    }
    if (latitude != null && (latitude < -90 || latitude > 90)) {
      throw const FormatException(
        'Career fair latitude is outside its valid range.',
      );
    }
    if (longitude != null && (longitude < -180 || longitude > 180)) {
      throw const FormatException(
        'Career fair longitude is outside its valid range.',
      );
    }

    final startTime = _optionalTime(json['start_time'], 'start_time');
    final endTime = _optionalTime(json['end_time'], 'end_time');
    if (endTime != null && startTime == null) {
      throw const FormatException(
        'Career fair end time requires a start time.',
      );
    }
    if (endTime != null && endTime <= startTime!) {
      throw const FormatException(
        'Career fair end time must be after its start time.',
      );
    }

    return CareerFair(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      organiser: _requiredString(json, 'organiser'),
      description: _requiredString(json, 'description'),
      eventDate: _calendarDate(json['event_date']),
      startTime: startTime,
      endTime: endTime,
      venue: _requiredString(json, 'venue'),
      address: _requiredString(json, 'address'),
      latitude: latitude,
      longitude: longitude,
      registrationUrl: _optionalString(json['registration_url']),
      sourceUrl: _optionalString(json['source_url']),
      createdAt: _requiredDateTime(json, 'created_at'),
      updatedAt: _requiredDateTime(json, 'updated_at'),
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw FormatException('Required field $key is missing.');
    }
    return value;
  }

  static String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime _calendarDate(Object? value) {
    final text = value?.toString();
    final match = text == null
        ? null
        : RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) throw const FormatException('Invalid event_date.');
    final date = DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    if (_dateKey(date) != text) {
      throw const FormatException('Invalid event_date.');
    }
    return date;
  }

  static DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    final parsed = value == null ? null : DateTime.tryParse(value.toString());
    if (parsed == null) {
      throw FormatException('Required field $key is invalid.');
    }
    return parsed;
  }

  static Duration? _optionalTime(Object? value, String key) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?$',
    ).firstMatch(text);
    if (match == null) throw FormatException('Invalid $key.');
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final second = int.tryParse(match.group(3) ?? '0') ?? 0;
    if (hour > 23 || minute > 59 || second > 59) {
      throw FormatException('Invalid $key.');
    }
    return Duration(hours: hour, minutes: minute, seconds: second);
  }

  static double? _optionalDouble(Object? value, String key) {
    if (value == null || value.toString().trim().isEmpty) return null;
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value.toString());
    if (parsed == null || !parsed.isFinite) {
      throw FormatException('Invalid $key.');
    }
    return parsed;
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
