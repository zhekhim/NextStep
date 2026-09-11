import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/local_database.dart';
import '../models/riasec_question.dart';

class AssessmentQuestionRepository {
  factory AssessmentQuestionRepository({
    SupabaseClient? client,
    LocalCache? cache,
  }) {
    return AssessmentQuestionRepository._(
      client,
      cache ?? LocalDatabase.instance,
    );
  }

  AssessmentQuestionRepository._(this._client, this._cache);

  final SupabaseClient? _client;
  final LocalCache _cache;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<List<RiasecQuestion>> getActiveQuestions() async {
    try {
      return await refreshQuestions();
    } catch (_) {
      final cached = await getCachedQuestions();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<List<RiasecQuestion>> getCachedQuestions() async =>
      (await _cache.readAssessmentQuestions())
          .map(RiasecQuestion.fromJson)
          .toList(growable: false);

  Future<List<RiasecQuestion>> refreshQuestions() async {
    final rows = await _supabase
        .from('assessment_questions')
        .select()
        .order('question_order');
    final questions = rows.map(RiasecQuestion.fromJson).toList(growable: false);
    try {
      await _cache.replaceAssessmentQuestions(
        questions
            .map(
              (question) => <String, Object?>{
                'id': question.id,
                'question_text': question.activity,
                'dimension': question.dimension,
                'question_order': question.order,
                'updated_at': question.updatedAt?.toUtc().toIso8601String(),
              },
            )
            .toList(growable: false),
      );
    } catch (_) {
      // Questions from Supabase remain usable if local caching fails.
    }
    return questions;
  }
}
