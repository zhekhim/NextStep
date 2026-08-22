import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationResult {
  const RegistrationResult({required this.requiresEmailConfirmation});

  final bool requiresEmailConfirmation;
}

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'full_name': fullName.trim()},
    );

    if (response.user == null) {
      throw const AuthException('Account registration was not completed.');
    }

    return RegistrationResult(
      requiresEmailConfirmation: response.session == null,
    );
  }
}
