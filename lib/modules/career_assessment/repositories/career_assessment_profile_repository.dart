import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/career_assessment_profile.dart';

class CareerAssessmentProfileRepository {
  factory CareerAssessmentProfileRepository({SupabaseClient? client}) {
    return CareerAssessmentProfileRepository._(client);
  }

  CareerAssessmentProfileRepository._(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<List<CareerAssessmentProfile>> getProfiles() async {
    final rows = await _supabase.from('career_assessment_profiles').select();
    return rows.map(CareerAssessmentProfile.fromJson).toList(growable: false);
  }
}
