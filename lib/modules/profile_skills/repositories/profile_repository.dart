import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/local_database.dart';
import '../models/profile.dart';

class ProfileRepository {
  factory ProfileRepository({SupabaseClient? client, LocalCache? cache}) {
    return ProfileRepository._(client, cache ?? LocalDatabase.instance);
  }

  ProfileRepository._(this._client, this._cache);

  static final _profileChanges = StreamController<void>.broadcast();

  static Stream<void> get profileChanges => _profileChanges.stream;

  final SupabaseClient? _client;
  final LocalCache _cache;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<Profile> getCurrentProfile() async {
    try {
      return await refreshCurrentProfile();
    } catch (_) {
      final cached = await getCachedProfile();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Profile?> getCachedProfile({String? userId}) async {
    final user = _supabase.auth.currentUser;
    final resolvedUserId = userId ?? user?.id;
    if (resolvedUserId == null) {
      throw const AuthException('No signed-in user was found.');
    }
    final row = await _cache.readProfile(resolvedUserId);
    if (row == null) return null;
    final roles = jsonDecode(row['targeted_roles']?.toString() ?? '[]');
    return Profile(
      userId: row['user_id'].toString(),
      fullName: row['full_name'].toString(),
      email: row['email'].toString(),
      university: _text(row['university']),
      major: _text(row['major']),
      yearOfStudy: _text(row['year_of_study']),
      preferredEmploymentState: _text(row['preferred_employment_state']),
      avatarUrl: _text(row['avatar_url']),
      title: _text(row['title']),
      bio: _text(row['bio']),
      targetedJobRoles: roles is List
          ? roles.map((role) => role.toString()).toList(growable: false)
          : const [],
    );
  }

  Future<Profile> refreshCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user was found.');
    }

    final row = await _supabase
        .from('profiles')
        .select('full_name, university, major, study_year')
        .eq('id', user.id)
        .maybeSingle();
    String? goalCareerName;
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

    final profile = Profile(
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
    await cacheProfile(profile);
    return profile;
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
      UserAttributes(data: {'title': title.trim(), 'bio': bio.trim()}),
    );
    final metadata = _supabase.auth.currentUser?.userMetadata ?? const {};
    await cacheProfile(
      Profile(
        userId: user.id,
        fullName: fullName.trim(),
        email: user.email ?? 'Email unavailable',
        university: university.trim(),
        major: major.trim(),
        yearOfStudy: studyYear.toString(),
        preferredEmploymentState: _text(metadata['preferred_employment_state']),
        avatarUrl: _text(metadata['avatar_url']),
        title: title.trim(),
        bio: bio.trim(),
        targetedJobRoles: targetedJobRoles,
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
    try {
      final cached = await getCachedProfile();
      if (cached != null) {
        await cacheProfile(
          cached.copyWith(
            targetedJobRoles: careerName == null ? const [] : [careerName],
          ),
        );
      }
    } catch (_) {
      // The Supabase update remains successful if the cache is unavailable.
    }
    _profileChanges.add(null);
  }

  Future<void> cacheAvatarUrl(String avatarUrl) async {
    try {
      final cached = await getCachedProfile();
      if (cached != null) {
        await cacheProfile(cached.copyWith(avatarUrl: avatarUrl));
      }
    } catch (_) {
      // The Storage upload remains successful if the cache is unavailable.
    }
  }

  Future<void> cacheProfile(Profile profile) async {
    try {
      await _cache.upsertProfile({
        'user_id': profile.userId,
        'full_name': profile.fullName,
        'email': profile.email,
        'university': profile.university,
        'major': profile.major,
        'year_of_study': profile.yearOfStudy,
        'preferred_employment_state': profile.preferredEmploymentState,
        'targeted_roles': jsonEncode(profile.targetedJobRoles),
        'avatar_url': profile.avatarUrl,
        'title': profile.title,
        'bio': profile.bio,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // A local cache failure must not undo a successful Supabase operation.
    }
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
