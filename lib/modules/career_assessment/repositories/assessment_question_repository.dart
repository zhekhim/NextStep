import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/riasec_question.dart';

class AssessmentQuestionRepository {
  factory AssessmentQuestionRepository({SupabaseClient? client}) {
    return AssessmentQuestionRepository._(client);
  }

  AssessmentQuestionRepository._(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<List<RiasecQuestion>> getActiveQuestions() async {
    final rows = await _supabase
        .from('assessment_questions')
        .select()
        .order('question_order');
    return rows.map(RiasecQuestion.fromJson).toList(growable: false);
  }
}
