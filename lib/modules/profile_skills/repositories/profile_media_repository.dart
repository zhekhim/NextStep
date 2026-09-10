import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileMediaRepository {
  ProfileMediaRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw const AuthException('Your login session has expired. Please log in again.');
    }
    await _supabase.auth.refreshSession();
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('No signed-in user was found.');
    }
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    await _supabase.storage.from('profile-photos').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );
    final url = _supabase.storage.from('profile-photos').getPublicUrl(path);
    await _supabase.auth.updateUser(UserAttributes(data: {'avatar_url': url}));
    return url;
  }
}
