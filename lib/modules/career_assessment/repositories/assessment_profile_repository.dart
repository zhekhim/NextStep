import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/assessment_profile.dart';
import '../services/riasec_scoring_service.dart';

class AssessmentProfileRepository {
  factory AssessmentProfileRepository({SupabaseClient? client}) {
    return AssessmentProfileRepository._(client);
  }

  AssessmentProfileRepository._(this._client);

  static final _assessmentChanges = StreamController<void>.broadcast();
  static Stream<void> get assessmentChanges => _assessmentChanges.stream;

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<String> saveResult(RiasecResult result) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('A signed-in user is required to save an assessment.');
    }

    final scores = AssessmentProfile.scoreFields(result);
    final now = DateTime.now().toUtc().toIso8601String();
    final id = const Uuid().v4();
    await _supabase.from('assessment_profiles').insert({
      'id': id,
      'user_id': userId,
      ...scores,
      'riasec_code': result.code,
      'created_at': now,
      'updated_at': now,
    });
    _assessmentChanges.add(null);
    return id;
  }

  Future<AssessmentProfile?> getLatestResult() async {
    final userId = _requiredUserId('load an assessment');
    final rows = await _supabase
        .from('assessment_profiles')
        .select(
          'id, created_at, riasec_code, realistic, investigative, artistic, social, enterprising, conventional',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return AssessmentProfile.fromJson(
      rows.first,
      questionCounts: await _getQuestionCounts(),
    );
  }

  Future<List<AssessmentProfile>> getHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError(
        'A signed-in user is required to view assessment history.',
      );
    }

    final rows = await _supabase
        .from('assessment_profiles')
        .select(
          'id, created_at, riasec_code, realistic, investigative, artistic, social, enterprising, conventional',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    final counts = await _getQuestionCounts();
    return rows
        .map((row) => AssessmentProfile.fromJson(row, questionCounts: counts))
        .toList(growable: false);
  }

  String _requiredUserId(String action) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('A signed-in user is required to $action.');
    }
    return userId;
  }

  Future<Map<String, int>> _getQuestionCounts() async {
    final questionRows = await _supabase
        .from('assessment_questions')
        .select('dimension');
    final counts = <String, int>{};
    for (final row in questionRows) {
      final code = _dimensionCode(row['dimension']);
      if (code != null) counts[code] = (counts[code] ?? 0) + 1;
    }
    return counts;
  }

  String? _dimensionCode(Object? value) {
    const codes = {
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
    return codes[value?.toString().trim().toUpperCase()];
  }
}
