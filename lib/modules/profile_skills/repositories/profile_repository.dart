import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileRepository {
  factory ProfileRepository({SupabaseClient? client}) {
    return ProfileRepository._(client);
  }

  ProfileRepository._(this._client);

  static final _profileChanges = StreamController<void>.broadcast();

  static Stream<void> get profileChanges => _profileChanges.stream;

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<Profile> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user was found.');
    }

    Map<String, dynamic>? row;
    String? goalCareerName;
    try {
      row = await _supabase
          .from('profiles')
          .select('full_name, university, major, study_year')
          .eq('id', user.id)
          .maybeSingle();
    } on PostgrestException {
      row = null;
    }
    try {
      final goal = await _supabase
          .from('career_goals')
          .select('careers(career_name)')
          .eq('user_id', user.id)
          .maybeSingle();
      final career = goal?['careers'];
      if (career is Map) goalCareerName = _text(career['career_name']);
    } on PostgrestException {
      goalCareerName = null;
    }
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName =
        _text(row?['full_name']) ??
        _text(metadata['full_name']) ??
        _text(metadata['name']) ??
        _nameFromEmail(user.email);

    return Profile(
      userId: user.id,
      fullName: fullName,
      email: user.email ?? 'Email unavailable',
      university: _text(row?['university']) ?? _text(metadata['university']),
      major: _text(row?['major']) ?? _text(metadata['major']),
      yearOfStudy:
          row?['study_year']?.toString() ?? metadata['study_year']?.toString(),
      preferredEmploymentState: _text(metadata['preferred_employment_state']),
      avatarUrl: _text(metadata['avatar_url']),
      title: _text(metadata['title']),
      bio: _text(metadata['bio']),
      targetedJobRoles: goalCareerName == null
          ? const []
          : <String>[goalCareerName],
    );
  }

  Future<void> updateProfile({
    required String fullName,
    required String university,
    required String major,
    required int studyYear,
    String title = '',
    String bio = '',
    List<String> targetedJobRoles = const [],
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user was found.');
    }

    final profileData = <String, dynamic>{
      'full_name': fullName.trim(),
      'university': university.trim(),
      'major': major.trim(),
      'study_year': studyYear,
    };

    await _supabase.from('profiles').upsert({
      'id': user.id,
      ...profileData,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'id');

    await _supabase.auth.updateUser(
      UserAttributes(
        data: {
          'title': title.trim(),
          'bio': bio.trim(),
        },
      ),
    );
    _profileChanges.add(null);
  }

  Future<void> syncTargetedRole(String? careerName) async {
    await _supabase.auth.updateUser(
      UserAttributes(
        data: {
          'targeted_job_roles': careerName == null
              ? const <String>[]
              : <String>[careerName],
        },
      ),
    );
    _profileChanges.add(null);
  }

  String? _text(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  String _nameFromEmail(String? email) {
    final localPart = email?.split('@').first.trim() ?? '';
    if (localPart.isEmpty) return 'NextStep Student';
    return localPart
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

}
