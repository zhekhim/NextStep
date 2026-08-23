import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assessment_question.dart';
import '../models/career_assessment_profile.dart';

class AssessmentRepository {
  factory AssessmentRepository({SupabaseClient? client}) {
    return AssessmentRepository._(client);
  }

  AssessmentRepository._(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<List<AssessmentQuestion>> getActiveQuestions() async {
    final rows = await _supabase
        .from('assessment_questions')
        .select('id, question_text, dimension, question_order')
        .eq('is_active', true)
        .order('question_order');

    return rows.map(AssessmentQuestion.fromJson).toList(growable: false);
  }

  Future<List<CareerAssessmentProfile>> getCareerAssessmentProfiles() async {
    final rows = await _supabase.from('career_assessment_profiles').select('''
      id,
      career_id,
      technical,
      analytical,
      creative,
      business,
      leadership,
      research,
      careers!inner(
        id,
        career_name,
        category,
        description,
        created_at,
        updated_at
      )
    ''');

    return rows.map(CareerAssessmentProfile.fromJson).toList(growable: false);
  }
}
