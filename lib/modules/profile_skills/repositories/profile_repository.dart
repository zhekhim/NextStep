import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileRepository {
  factory ProfileRepository({SupabaseClient? client}) {
    return ProfileRepository._(client);
  }

  ProfileRepository._(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<Profile> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user was found.');
    }

    Map<String, dynamic>? row;
    try {
      row = await _supabase
          .from('profiles')
          .select('full_name, university, major, study_year')
          .eq('id', user.id)
          .maybeSingle();
    } on PostgrestException {
      row = null;
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
      university:
          _text(row?['university']) ?? _text(metadata['university']),
      major: _text(row?['major']) ?? _text(metadata['major']),
      yearOfStudy:
          row?['study_year']?.toString() ??
          metadata['study_year']?.toString(),
      preferredEmploymentState: _text(metadata['preferred_employment_state']),
      avatarUrl: _text(metadata['avatar_url']),
    );
  }

  Future<void> updateProfile({
    required String fullName,
    required String university,
    required String major,
    required int studyYear,
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
