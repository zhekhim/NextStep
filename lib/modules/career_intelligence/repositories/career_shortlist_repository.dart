import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/career_shortlist.dart';

class DuplicateCareerShortlistException implements Exception {
  const DuplicateCareerShortlistException();

  @override
  String toString() => 'This career is already in your interested careers.';
}

class CareerShortlistAuthException implements Exception {
  const CareerShortlistAuthException();

  @override
  String toString() => 'Please sign in to manage your interested careers.';
}

abstract class CareerShortlistRepository {
  Future<List<CareerShortlist>> getShortlistedCareers();
  Future<CareerShortlist?> getShortlistForCareer(String careerId);
  Future<CareerShortlist> addCareer({
    String status = 'Interested',
    required String careerId,
    String? priority,
    String? notes,
  });
  Future<CareerShortlist> updateCareer({
    String? status,
    required String shortlistId,
    required String? priority,
    required String? notes,
  });
  Future<void> removeCareer(String shortlistId);
}

class SupabaseCareerShortlistRepository implements CareerShortlistRepository {
  factory SupabaseCareerShortlistRepository({SupabaseClient? client}) {
    return SupabaseCareerShortlistRepository._(client);
  }

  SupabaseCareerShortlistRepository._(this._client);

  static const _select = '''
    id, user_id, priority, notes, status, created_at, updated_at,
    careers!inner(id, career_name, category, description, created_at, updated_at)
  ''';

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const CareerShortlistAuthException();
    return id;
  }

  @override
  Future<List<CareerShortlist>> getShortlistedCareers() async {
    final rows = await _supabase
        .from('career_shortlists')
        .select(_select)
        .eq('user_id', _userId);
    final items = rows.map(CareerShortlist.fromJson).toList();
    items.sort(_compare);
    return items;
  }

  @override
  Future<CareerShortlist?> getShortlistForCareer(String careerId) async {
    final rows = await _supabase
        .from('career_shortlists')
        .select(_select)
        .eq('user_id', _userId)
        .eq('career_id', careerId)
        .limit(1);
    return rows.isEmpty ? null : CareerShortlist.fromJson(rows.first);
  }

  @override
  Future<CareerShortlist> addCareer({
    String status = 'Interested',
    required String careerId,
    String? priority,
    String? notes,
  }) async {
    final validPriority = CareerShortlist.validatePriority(priority);
    final validNotes = CareerShortlist.normalizeNotes(notes);
    try {
      final row = await _supabase
          .from('career_shortlists')
          .insert({
            'user_id': _userId,
            'career_id': careerId,
            'priority': validPriority,
            'notes': validNotes,
            'status': CareerShortlist.validateStatus(status),
          })
          .select(_select)
          .single();
      return CareerShortlist.fromJson(row);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const DuplicateCareerShortlistException();
      }
      rethrow;
    }
  }

  @override
  Future<CareerShortlist> updateCareer({
    String? status,
    required String shortlistId,
    required String? priority,
    required String? notes,
  }) async {
    final row = await _supabase
        .from('career_shortlists')
        .update({
          'priority': CareerShortlist.validatePriority(priority),
          'notes': CareerShortlist.normalizeNotes(notes),
          if (status != null) 'status': CareerShortlist.validateStatus(status),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', shortlistId)
        .eq('user_id', _userId)
        .select(_select)
        .single();
    return CareerShortlist.fromJson(row);
  }

  @override
  Future<void> removeCareer(String shortlistId) async {
    await _supabase
        .from('career_shortlists')
        .delete()
        .eq('id', shortlistId)
        .eq('user_id', _userId);
  }

  static int _compare(CareerShortlist a, CareerShortlist b) {
    const order = {'High': 0, 'Medium': 1, 'Low': 2};
    final priority = (order[a.priority] ?? 3).compareTo(order[b.priority] ?? 3);
    return priority != 0
        ? priority
        : a.career.careerName.compareTo(b.career.careerName);
  }
}
