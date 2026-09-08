import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/career_fair.dart';

abstract class CareerFairRepository {
  Future<List<CareerFair>> getUpcomingCareerFairs({DateTime? now});
  Future<List<CareerFair>> getPastCareerFairs({DateTime? now});
  Future<CareerFair?> getCareerFairById(String id);
}

class SupabaseCareerFairRepository implements CareerFairRepository {
  factory SupabaseCareerFairRepository({SupabaseClient? client}) {
    return SupabaseCareerFairRepository._(client);
  }

  SupabaseCareerFairRepository._(this._client);

  static const _columns = '''
    id, title, organiser, description, event_date, start_time, end_time,
    venue, address, latitude, longitude, registration_url, source_url,
    created_at, updated_at
  ''';

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  @override
  Future<List<CareerFair>> getUpcomingCareerFairs({DateTime? now}) async {
    final today = malaysiaToday(now ?? DateTime.now());
    final rows = await _supabase
        .from('career_fairs')
        .select(_columns)
        .gte('event_date', dateKey(today));
    final fairs = rows.map(CareerFair.fromJson).toList();
    fairs.sort(compareUpcoming);
    return fairs;
  }

  @override
  Future<List<CareerFair>> getPastCareerFairs({DateTime? now}) async {
    final today = malaysiaToday(now ?? DateTime.now());
    final rows = await _supabase
        .from('career_fairs')
        .select(_columns)
        .lt('event_date', dateKey(today));
    final fairs = rows.map(CareerFair.fromJson).toList();
    fairs.sort(comparePast);
    return fairs;
  }

  @override
  Future<CareerFair?> getCareerFairById(String id) async {
    final rows = await _supabase
        .from('career_fairs')
        .select(_columns)
        .eq('id', id)
        .limit(1);
    return rows.isEmpty ? null : CareerFair.fromJson(rows.first);
  }

  static DateTime malaysiaToday(DateTime now) {
    final malaysiaNow = now.toUtc().add(const Duration(hours: 8));
    return DateTime(malaysiaNow.year, malaysiaNow.month, malaysiaNow.day);
  }

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static int compareUpcoming(CareerFair a, CareerFair b) {
    final date = a.eventDate.compareTo(b.eventDate);
    if (date != 0) return date;
    final time = _compareTimes(a.startTime, b.startTime, descending: false);
    return time != 0 ? time : a.title.compareTo(b.title);
  }

  static int comparePast(CareerFair a, CareerFair b) {
    final date = b.eventDate.compareTo(a.eventDate);
    if (date != 0) return date;
    final time = _compareTimes(a.startTime, b.startTime, descending: true);
    return time != 0 ? time : a.title.compareTo(b.title);
  }

  static int _compareTimes(
    Duration? a,
    Duration? b, {
    required bool descending,
  }) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return descending ? b.compareTo(a) : a.compareTo(b);
  }
}
