import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/career_goal.dart';
import '../models/career_requirement.dart';

class CareerGoalRepository {
  factory CareerGoalRepository({SupabaseClient? client}) {
    return CareerGoalRepository._(client);
  }

  CareerGoalRepository._(this._client);
  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;
  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const AuthException('No signed-in user was found.');
    return id;
  }

  Future<List<CareerOption>> getCareers() async {
    final rows = await _supabase
        .from('careers')
        .select('id, career_name, category')
        .order('career_name');
    return rows.map(CareerOption.fromMap).toList();
  }

  Future<CareerGoal?> getGoal() async {
    final rows = await _supabase
        .from('career_goals')
        .select(
          'id, user_id, preferred_state, target_graduation_year, expected_salary, status, careers(id, career_name, category)',
        )
        .eq('user_id', _userId)
        .limit(1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return CareerGoal(
      id: row['id'].toString(),
      userId: row['user_id'].toString(),
      career: CareerOption.fromMap(
        Map<String, dynamic>.from(row['careers'] as Map),
      ),
      preferredState: row['preferred_state'] as String?,
      targetGraduationYear: row['target_graduation_year'] as int?,
      expectedSalary: (row['expected_salary'] as num?)?.toDouble(),
      status: row['status'].toString(),
    );
  }

  Future<void> saveGoal({
    required CareerOption career,
    String? preferredState,
    int? targetGraduationYear,
    double? expectedSalary,
    String status = 'Active',
  }) async {
    await _supabase.from('career_goals').upsert({
      'user_id': _userId,
      'career_id': career.id,
      'preferred_state': preferredState,
      'target_graduation_year': targetGraduationYear,
      'expected_salary': expectedSalary,
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  Future<void> deleteGoal() =>
      _supabase.from('career_goals').delete().eq('user_id', _userId);

  Future<List<CareerRequirement>> getRequirements(String careerId) async {
    final links = await _supabase
        .from('career_skills')
        .select('skill_id, required_level')
        .eq('career_id', careerId);
    if (links.isEmpty) return const [];
    final ids = links.map((row) => row['skill_id']).toSet().toList();
    final skills = await _supabase
        .from('skills')
        .select('id, skill_name')
        .inFilter('id', ids);
    final names = {
      for (final row in skills)
        row['id'].toString(): row['skill_name'].toString(),
    };
    final result =
        links
            .map(
              (row) => CareerRequirement(
                skillId: row['skill_id'].toString(),
                skillName: names[row['skill_id'].toString()] ?? 'Unknown skill',
                requiredLevel: row['required_level']?.toString() ?? 'Beginner',
              ),
            )
            .toList()
          ..sort((a, b) => a.skillName.compareTo(b.skillName));
    return result;
  }
}
