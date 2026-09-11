class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://your-project.supabase.co';
  static const String secretKey = 'your-secret-key-here';

  static bool get hasCredentials => url.isNotEmpty && secretKey.isNotEmpty;
}
