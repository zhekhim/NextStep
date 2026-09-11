import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/local_database.dart';
import '../models/career_fair.dart';

abstract class CareerFairRepository {
  Future<List<CareerFair>> getUpcomingCareerFairs({DateTime? now});
  Future<List<CareerFair>> getPastCareerFairs({DateTime? now});
  Future<CareerFair?> getCareerFairById(String id);
}

class SupabaseCareerFairRepository implements CareerFairRepository {
  factory SupabaseCareerFairRepository({
    SupabaseClient? client,
    LocalCache? cache,
  }) {
    return SupabaseCareerFairRepository._(
      client,
      cache ?? LocalDatabase.instance,
    );
  }

  SupabaseCareerFairRepository._(this._client, this._cache);

  static const _columns = '''
    id, title, organiser, description, event_date, start_time, end_time,
    venue, address, latitude, longitude, registration_url, source_url,
    created_at, updated_at
  ''';

  final SupabaseClient? _client;
  final LocalCache _cache;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  @override
  Future<List<CareerFair>> getUpcomingCareerFairs({DateTime? now}) async {
    final today = malaysiaToday(now ?? DateTime.now());
    late final List<CareerFair> fairs;
    try {
      fairs = await _fetchAllCareerFairs();
    } catch (_) {
      final cached = await getCachedCareerFairs();
      if (cached.isNotEmpty) return _upcoming(cached, today);
      rethrow;
    }
    await _cacheCareerFairs(fairs);
    return _upcoming(fairs, today);
  }

  @override
  Future<List<CareerFair>> getPastCareerFairs({DateTime? now}) async {
    final today = malaysiaToday(now ?? DateTime.now());
    late final List<CareerFair> fairs;
    try {
      fairs = await _fetchAllCareerFairs();
    } catch (_) {
      final cached = await getCachedCareerFairs();
      if (cached.isNotEmpty) return _past(cached, today);
      rethrow;
    }
    await _cacheCareerFairs(fairs);
    return _past(fairs, today);
  }

  @override
  Future<CareerFair?> getCareerFairById(String id) async {
    try {
      final rows = await _supabase
          .from('career_fairs')
          .select(_columns)
          .eq('id', id)
          .limit(1);
      return rows.isEmpty ? null : CareerFair.fromJson(rows.first);
    } catch (_) {
      final cached = await getCachedCareerFairs();
      for (final fair in cached) {
        if (fair.id == id) return fair;
      }
      rethrow;
    }
  }

  Future<List<CareerFair>> getCachedCareerFairs() async =>
      (await _cache.readCareerFairs())
          .map(CareerFair.fromJson)
          .toList(growable: false);

  Future<List<CareerFair>> _fetchAllCareerFairs() async {
    final rows = await _supabase.from('career_fairs').select(_columns);
    return rows.map(CareerFair.fromJson).toList(growable: false);
  }

  Future<void> _cacheCareerFairs(List<CareerFair> fairs) async {
    try {
      await _cache.replaceCareerFairs(fairs.map(_toCacheRow).toList());
    } catch (_) {
      // The online result remains usable if the optional cache is unavailable.
    }
  }

  List<CareerFair> _upcoming(List<CareerFair> fairs, DateTime today) =>
      fairs.where((fair) => !fair.eventDate.isBefore(today)).toList()
        ..sort(compareUpcoming);

  List<CareerFair> _past(List<CareerFair> fairs, DateTime today) =>
      fairs.where((fair) => fair.eventDate.isBefore(today)).toList()
        ..sort(comparePast);

  Map<String, Object?> _toCacheRow(CareerFair fair) => {
    'id': fair.id,
    'title': fair.title,
    'organiser': fair.organiser,
    'description': fair.description,
    'event_date': dateKey(fair.eventDate),
    'start_time': _timeText(fair.startTime),
    'end_time': _timeText(fair.endTime),
    'venue': fair.venue,
    'address': fair.address,
    'latitude': fair.latitude,
    'longitude': fair.longitude,
    'registration_url': fair.registrationUrl,
    'source_url': fair.sourceUrl,
    'created_at': fair.createdAt.toUtc().toIso8601String(),
    'updated_at': fair.updatedAt.toUtc().toIso8601String(),
  };

  String? _timeText(Duration? value) {
    if (value == null) return null;
    final hours = value.inHours.toString().padLeft(2, '0');
    final minutes = (value.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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
