import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/career_recommendation_evaluation.dart';

class CareerRecommendationEvaluationRepository {
  factory CareerRecommendationEvaluationRepository({SupabaseClient? client}) {
    return CareerRecommendationEvaluationRepository._(client);
  }

  CareerRecommendationEvaluationRepository._(this._client);

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  String get _userId {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw StateError('Please sign in to evaluate a career.');
    return userId;
  }

  Future<CareerRecommendationEvaluation?> getEvaluation({
    required String assessmentProfileId,
    required String careerId,
  }) async {
    final rows = await _supabase
        .from('career_recommendation_evaluations')
        .select('id, assessment_profile_id, career_id, rating, comment')
        .eq('user_id', _userId)
        .eq('assessment_profile_id', assessmentProfileId)
        .eq('career_id', careerId)
        .limit(1);
    return rows.isEmpty
        ? null
        : CareerRecommendationEvaluation.fromJson(rows.first);
  }

  Future<CareerRecommendationEvaluation> save({
    CareerRecommendationEvaluation? existing,
    required String assessmentProfileId,
    required String careerId,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Select a rating from 1 to 5.');
    }
    final values = {
      'rating': rating,
      'comment': _comment(comment),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final row = existing == null
        ? await _supabase.from('career_recommendation_evaluations').insert({
            ...values,
            'user_id': _userId,
            'assessment_profile_id': assessmentProfileId,
            'career_id': careerId,
          }).select('id, assessment_profile_id, career_id, rating, comment').single()
        : await _supabase.from('career_recommendation_evaluations').update(values)
            .eq('id', existing.id).eq('user_id', _userId)
            .select('id, assessment_profile_id, career_id, rating, comment').single();
    return CareerRecommendationEvaluation.fromJson(row);
  }

  Future<void> delete(String id) => _supabase
      .from('career_recommendation_evaluations')
      .delete()
      .eq('id', id)
      .eq('user_id', _userId);

  String? _comment(String? value) {
    final comment = value?.trim();
    if (comment == null || comment.isEmpty) return null;
    if (comment.length > 1000) {
      throw ArgumentError('Comment must be 1,000 characters or fewer.');
    }
    return comment;
  }
}
