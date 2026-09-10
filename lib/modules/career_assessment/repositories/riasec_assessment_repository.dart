import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/riasec_assessment_profile.dart';
import '../services/riasec_scoring_service.dart';

class RiasecAssessmentRepository {
  RiasecAssessmentRepository({SupabaseClient? client}) : _client = client;

  static final _assessmentChanges = StreamController<void>.broadcast();
  static Stream<void> get assessmentChanges => _assessmentChanges.stream;

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const AuthException('No signed-in user was found.');
    return id;
  }

  Future<RiasecAssessmentProfile?> getCurrentResult() async {
    final rows = await _supabase
        .from('assessment_profiles')
        .select(
          'realistic, investigative, artistic, social, enterprising, conventional, riasec_code',
        )
        .eq('user_id', _userId)
        .order('updated_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final code = row['riasec_code']?.toString();
    if (code == null || code.length != 3) return null;
    return RiasecAssessmentProfile(
      code: code,
      scores: {
        'R': (row['realistic'] as num?)?.toInt() ?? 0,
        'I': (row['investigative'] as num?)?.toInt() ?? 0,
        'A': (row['artistic'] as num?)?.toInt() ?? 0,
        'S': (row['social'] as num?)?.toInt() ?? 0,
        'E': (row['enterprising'] as num?)?.toInt() ?? 0,
        'C': (row['conventional'] as num?)?.toInt() ?? 0,
      },
    );
  }

  Future<void> saveResult(RiasecResult result) async {
    final totals = {
      for (final score in result.rankedScores) score.dimension: score.total,
    };
    final values = {
      'user_id': _userId,
      'realistic': totals['R'],
      'investigative': totals['I'],
      'artistic': totals['A'],
      'social': totals['S'],
      'enterprising': totals['E'],
      'conventional': totals['C'],
      'riasec_code': result.code,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final existing = await _supabase
        .from('assessment_profiles')
        .select('id')
        .eq('user_id', _userId)
        .limit(1);
    if (existing.isEmpty) {
      await _supabase.from('assessment_profiles').insert(values);
    } else {
      await _supabase
          .from('assessment_profiles')
          .update(values)
          .eq('user_id', _userId);
    }
    _assessmentChanges.add(null);
  }
}
