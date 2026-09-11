import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

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
    var session = _supabase.auth.currentSession;
    if (session == null) {
      throw StateError('A signed-in user is required to save an assessment.');
    }
    if (session.isExpired) {
      session = (await _supabase.auth.refreshSession()).session;
      if (session == null) {
        throw StateError(
          'Your session has expired. Please sign in again before saving.',
        );
      }
    }

    final scores = AssessmentProfile.scoreFields(result);
    final row = await _supabase
        .from('assessment_profiles')
        .insert({
          'user_id': session.user.id,
          ...scores,
          'riasec_code': result.code,
        })
        .select('id')
        .single();
    _assessmentChanges.add(null);
    return row['id'].toString();
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
    return AssessmentProfile.fromJson(rows.first);
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
    return rows.map(AssessmentProfile.fromJson).toList(growable: false);
  }

  String _requiredUserId(String action) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('A signed-in user is required to $action.');
    }
    return userId;
  }
}
