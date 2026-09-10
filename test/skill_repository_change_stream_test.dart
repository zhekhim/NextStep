import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/profile_skills/repositories/skill_repository.dart';

void main() {
  test('skill change notifications support multiple interested screens', () {
    expect(SkillRepository.skillChanges.isBroadcast, isTrue);
  });

  test('manual skill change notification reaches listening screens', () async {
    final nextChange = SkillRepository.skillChanges.first;

    SkillRepository.notifySkillsChanged();

    await expectLater(nextChange, completes);
  });
}
