import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/career.dart';
import '../models/career_skill.dart';

class CareerRepository {
  factory CareerRepository({SupabaseClient? client}) {
    return CareerRepository._(client);
  }

  CareerRepository._(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<List<Career>> getCareers() async {
    final rows = await _supabase
        .from('careers')
        .select(
          'id, career_name, category, description, created_at, updated_at',
        )
        .order('career_name');

    return rows.map(Career.fromJson).toList(growable: false);
  }

  Future<List<CareerSkill>> getSkillsForCareer(String careerId) async {
    final requirementRows = await _supabase
        .from('career_skills')
        .select('skill_id, required_level')
        .eq('career_id', careerId);
    if (requirementRows.isEmpty) return const [];

    final skillIds = requirementRows
        .map((row) => row['skill_id'])
        .where((id) => id != null)
        .cast<Object>()
        .toSet()
        .toList();
    final skillRows = await _supabase
        .from('skills')
        .select('id, skill_name, category')
        .inFilter('id', skillIds);
    final skillsById = {for (final row in skillRows) row['id'].toString(): row};

    final skills = <CareerSkill>[];
    for (final requirement in requirementRows) {
      final skillId = requirement['skill_id'].toString();
      final skill = skillsById[skillId];
      if (skill == null) continue;

      skills.add(
        CareerSkill(
          skillId: skillId,
          skillName: skill['skill_name'].toString(),
          category: skill['category'].toString(),
          requiredLevel: requirement['required_level'].toString(),
        ),
      );
    }

    const levelOrder = {'Advanced': 0, 'Intermediate': 1, 'Beginner': 2};
    skills.sort((a, b) {
      final levelComparison = (levelOrder[a.requiredLevel] ?? 3).compareTo(
        levelOrder[b.requiredLevel] ?? 3,
      );
      return levelComparison != 0
          ? levelComparison
          : a.skillName.compareTo(b.skillName);
    });
    return skills;
  }
}
