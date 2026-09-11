import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/certification.dart';

class CertificationRepository {
  CertificationRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  String get _userId {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('No signed-in user was found.');
    }
    return userId;
  }

  Future<List<Certification>> getCertifications() async {
    final rows = await _supabase
        .from('certifications')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map(Certification.fromMap).toList();
  }

  Future<Certification> uploadCertification({
    required String title,
    required String issuer,
    required String fileName,
    required String fileType,
    required Uint8List bytes,
    DateTime? issuedDate,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('Certification title cannot be empty.');
    }
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$_userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final storage = _supabase.storage.from('certificates');
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: fileType, upsert: true),
    );
    try {
      final fileUrl = storage.getPublicUrl(path);
      final row = await _supabase
          .from('certifications')
          .insert({
            'user_id': _userId,
            'title': title.trim(),
            'issuer': issuer.trim(),
            'file_name': fileName,
            'file_url': fileUrl,
            'file_type': fileType,
            'issued_date': issuedDate?.toIso8601String(),
          })
          .select()
          .single();
      return Certification.fromMap(row);
    } catch (_) {
      await storage.remove([path]);
      rethrow;
    }
  }

  Future<void> deleteCertification(Certification certification) async {
    await _supabase
        .from('certifications')
        .delete()
        .eq('id', certification.id)
        .eq('user_id', _userId);
  }
}
