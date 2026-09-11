import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/core/supabase/supabase_config.dart';

void main() {
  test('uses the expected project and secret runtime setting', () {
    expect(SupabaseConfig.url, 'https://ahyqcqjopkvmgcpfguzr.supabase.co');
    expect(SupabaseConfig.secretKey, isA<String>());
  });
}
