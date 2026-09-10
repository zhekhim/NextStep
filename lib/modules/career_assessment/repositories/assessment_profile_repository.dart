import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/assessment_profile.dart';
import '../services/riasec_scoring_service.dart';

class AssessmentProfileRepository {
  factory AssessmentProfileRepository({SupabaseClient? client}) {
    return AssessmentProfileRepository._(client);
  }

  AssessmentProfileRepository._(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<void> saveResult(RiasecResult result) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('A signed-in user is required to save an assessment.');
    }

    final scores = AssessmentProfile.scoreFields(result);
    final now = DateTime.now().toUtc().toIso8601String();
    await _supabase.from('assessment_profiles').insert({
      'id': const Uuid().v4(),
      'user_id': userId,
      ...scores,
      'riasec_code': result.code,
      'created_at': now,
      'updated_at': now,
    });
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
    final questionRows = await _supabase
        .from('assessment_questions')
        .select('dimension');
    final counts = <String, int>{};
    for (final row in questionRows) {
      final code = _dimensionCode(row['dimension']);
      if (code != null) counts[code] = (counts[code] ?? 0) + 1;
    }
    return rows
        .map((row) => AssessmentProfile.fromJson(row, questionCounts: counts))
        .toList(growable: false);
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
