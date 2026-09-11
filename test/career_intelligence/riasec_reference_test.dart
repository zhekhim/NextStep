import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_intelligence/screens/career_interest_types_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/careers_hub_screen.dart';
import 'package:untitled/modules/career_intelligence/services/riasec_reference_service.dart';

void main() {
  const service = RiasecReferenceService();

  test('provides exactly the six ordered RIASEC types with attribution', () {
    final types = service.getTypes();

    expect(types, hasLength(6));
    expect(types.map((type) => type.code), ['R', 'I', 'A', 'S', 'E', 'C']);
    expect(types.map((type) => type.name), [
      'Realistic',
      'Investigative',
      'Artistic',
      'Social',
      'Enterprising',
      'Conventional',
    ]);
    expect(types.map((type) => type.code).toSet(), hasLength(6));
    for (final type in types) {
      expect(type.description.trim(), isNotEmpty);
      expect(type.sourceName, RiasecReferenceService.sourceName);
      expect(type.sourceUrl, 'https://eprofiling.mohe.gov.my/');
    }
  });

  testWidgets(
    'screen shows all types and source information without overflow',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CareerInterestTypesScreen()),
      );

      expect(find.text('Career Interest Types'), findsOneWidget);
      for (final type in service.getTypes()) {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('riasec-${type.code}')),
          150,
        );
        expect(find.text(type.name), findsOneWidget);
        expect(find.text(type.code), findsOneWidget);
      }
      await tester.scrollUntilVisible(
        find.textContaining('https://eprofiling.mohe.gov.my/'),
        150,
      );
      expect(
        find.textContaining('Ministry of Higher Education Malaysia (MOHE)'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text(RiasecReferenceService.translationNote),
        100,
      );
      expect(find.text(RiasecReferenceService.translationNote), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Careers Hub does not duplicate Career Interest Types', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CareersHubScreen()));
    expect(find.text('Career Interest Types'), findsNothing);
  });
}
