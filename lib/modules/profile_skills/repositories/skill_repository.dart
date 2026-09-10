import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_skill.dart';

class DuplicateSkillException implements Exception {
  const DuplicateSkillException(this.skillName);

  final String skillName;

  @override
  String toString() => '$skillName is already in your skill portfolio.';
}

class SkillRepository {
  factory SkillRepository({SupabaseClient? client}) {
    return SkillRepository._(client);
  }

  SkillRepository._(this._client);

  static final _skillChanges = StreamController<void>.broadcast();

  static Stream<void> get skillChanges => _skillChanges.stream;

  static void notifySkillsChanged() => _skillChanges.add(null);

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const AuthException('No signed-in user was found.');
    return id;
  }

  Future<List<SkillCatalogItem>> getSkillCatalog() async {
    final rows = await _supabase
        .from('skills')
        .select('id, skill_name, category')
        .order('category')
        .order('skill_name');
    return rows.map(SkillCatalogItem.fromMap).toList();
  }

  Future<List<UserSkill>> getUserSkills() async {
    final userSkillRows = await _supabase
        .from('user_skills')
        .select('id, user_id, skill_id, skill_level')
        .eq('user_id', _userId);
    if (userSkillRows.isEmpty) return const [];

    final skillIds = userSkillRows
        .map((row) => row['skill_id'])
        .where((id) => id != null)
        .cast<Object>()
        .toSet()
        .toList();
    final catalogRows = await _supabase
        .from('skills')
        .select('id, skill_name, category')
        .inFilter('id', skillIds);
    final catalogById = {
      for (final row in catalogRows)
        row['id'].toString(): SkillCatalogItem.fromMap(row),
    };

    final skills = <UserSkill>[];
    for (final row in userSkillRows) {
      final skill = catalogById[row['skill_id'].toString()];
      if (skill == null) continue;
      skills.add(
        UserSkill(
          id: row['id'].toString(),
          userId: row['user_id'].toString(),
          skill: skill,
          level: row['skill_level'].toString(),
        ),
      );
    }
    skills.sort((a, b) => a.skill.name.compareTo(b.skill.name));
    return skills;
  }

  Future<UserSkill> addSkill({
    required SkillCatalogItem skill,
    required String level,
  }) async {
    _validateLevel(level);
    try {
      final row = await _supabase
          .from('user_skills')
          .insert({
            'user_id': _userId,
            'skill_id': skill.id,
            'skill_level': level,
          })
          .select('id, user_id, skill_level')
          .single();
      final userSkill = UserSkill(
        id: row['id'].toString(),
        userId: row['user_id'].toString(),
        skill: skill,
        level: row['skill_level'].toString(),
      );
      notifySkillsChanged();
      return userSkill;
    } on PostgrestException catch (error) {
      if (error.code == '23505') throw DuplicateSkillException(skill.name);
      rethrow;
    }
  }

  Future<UserSkill> updateSkill({
    required UserSkill userSkill,
    required SkillCatalogItem skill,
    required String level,
  }) async {
    _validateLevel(level);
    try {
      final row = await _supabase
          .from('user_skills')
          .update({
            'skill_id': skill.id,
            'skill_level': level,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userSkill.id)
          .eq('user_id', _userId)
          .select('id, user_id, skill_level')
          .single();
      final updatedSkill = UserSkill(
        id: row['id'].toString(),
        userId: row['user_id'].toString(),
        skill: skill,
        level: row['skill_level'].toString(),
      );
      notifySkillsChanged();
      return updatedSkill;
    } on PostgrestException catch (error) {
      if (error.code == '23505') throw DuplicateSkillException(skill.name);
      rethrow;
    }
  }

  Future<void> deleteSkill(String userSkillId) async {
    await _supabase
        .from('user_skills')
        .delete()
        .eq('id', userSkillId)
        .eq('user_id', _userId);
    notifySkillsChanged();
  }

  void _validateLevel(String level) {
    if (!UserSkill.levels.contains(level)) {
      throw ArgumentError.value(
        level,
        'level',
        'Please select a valid skill level.',
      );
    }
  }
}
