import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationResult {
  const RegistrationResult({required this.requiresEmailConfirmation});

  final bool requiresEmailConfirmation;
}

class LoginResult {
  const LoginResult({required this.userId});

  final String userId;
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

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = response.user;
    if (user == null || response.session == null) {
      throw const AuthException('Login was not completed.');
    }

    return LoginResult(userId: user.id);
  }
}
