import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_intelligence/models/career_fair.dart';
import 'package:untitled/modules/career_intelligence/repositories/career_fair_repository.dart';
import 'package:untitled/modules/career_intelligence/screens/career_fair_detail_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/career_fairs_screen.dart';
import 'package:untitled/modules/career_intelligence/services/career_fair_map_service.dart';

void main() {
  CareerFair fair({
    String address = 'Level 3, Menara A & B, Kuala Lumpur',
    double? latitude = 3.139,
    double? longitude = 101.6869,
  }) => CareerFair(
    id: 'fair-1',
    title: 'Verified Career Fair',
    organiser: 'Verified Organiser',
    description: 'A verified recruitment event.',
    eventDate: DateTime(2026, 10, 20),
    startTime: const Duration(hours: 9),
    endTime: const Duration(hours: 17),
    venue: 'Convention Centre',
    address: address,
    latitude: latitude,
    longitude: longitude,
    registrationUrl: 'https://example.com/register',
    sourceUrl: 'https://example.com/source',
    createdAt: DateTime.utc(2026, 9, 8),
    updatedAt: DateTime.utc(2026, 9, 8),
  );

  Widget app(Widget child) => MaterialApp(home: child);

  group('CareerFairMapService URI construction', () {
    test('uses valid coordinates', () {
      final uri = CareerFairMapService().buildMapUri(fair());

      expect(uri?.scheme, 'https');
      expect(uri?.host, 'www.google.com');
      expect(uri?.path, '/maps/search/');
      expect(uri?.queryParameters['api'], '1');
      expect(uri?.queryParameters['query'], '3.139,101.6869');
    });

    test('uses an encoded address when coordinates are absent', () {
      final uri = CareerFairMapService().buildMapUri(
        fair(latitude: null, longitude: null),
      );

      expect(
        uri?.queryParameters['query'],
        'Level 3, Menara A & B, Kuala Lumpur',
      );
      expect(uri.toString(), isNot(contains(' ')));
      expect(uri.toString(), contains('%26'));
    });

    test('prefers coordinates over the address', () {
      final uri = CareerFairMapService().buildMapUri(
        fair(address: 'Different address'),
      );

      expect(uri?.queryParameters['query'], '3.139,101.6869');
    });

    test('returns no URI without a usable location', () {
      final uri = CareerFairMapService().buildMapUri(
        fair(address: ' ', latitude: null, longitude: null),
      );

      expect(uri, isNull);
    });

    test('falls back to address when constructor coordinates are invalid', () {
      final uri = CareerFairMapService().buildMapUri(
        fair(latitude: double.infinity, longitude: 101.6869),
      );

      expect(uri?.queryParameters['query'], fair().address);
    });
  });

  group('CareerFairMapService launching', () {
    test('returns successful launch result', () async {
      final service = CareerFairMapService(launcher: (_) async => true);

      expect(await service.launchLocation(fair()), isTrue);
    });

    test('returns failed launch result', () async {
      final service = CareerFairMapService(launcher: (_) async => false);

      expect(await service.launchLocation(fair()), isFalse);
    });

    test('converts a launcher exception to failure', () async {
      final service = CareerFairMapService(
        launcher: (_) => throw Exception('No external handler'),
      );

      expect(await service.launchLocation(fair()), isFalse);
    });

    test('does not call launcher without a usable location', () async {
      var calls = 0;
      final service = CareerFairMapService(
        launcher: (_) async {
          calls++;
          return true;
        },
      );

      final launched = await service.launchLocation(
        fair(address: ' ', latitude: null, longitude: null),
      );

      expect(launched, isFalse);
      expect(calls, 0);
    });
  });

  group('Career Fair detail map actions', () {
    testWidgets('shows map action only with a usable location', (tester) async {
      await tester.pumpWidget(app(CareerFairDetailScreen(careerFair: fair())));
      await tester.scrollUntilVisible(
        find.text('Open Venue in Maps'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Open Venue in Maps'), findsOneWidget);

      await tester.pumpWidget(
        app(
          CareerFairDetailScreen(
            careerFair: fair(address: ' ', latitude: null, longitude: null),
          ),
        ),
      );
      expect(find.text('Open Venue in Maps'), findsNothing);
      expect(find.text('Copy Address'), findsNothing);
    });

    testWidgets('shows progress and blocks repeated launches', (tester) async {
      final pending = Completer<bool>();
      var calls = 0;
      final service = CareerFairMapService(
        launcher: (_) {
          calls++;
          return pending.future;
        },
      );
      await tester.pumpWidget(
        app(CareerFairDetailScreen(careerFair: fair(), mapService: service)),
      );

      await tester.scrollUntilVisible(
        find.text('Open Venue in Maps'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Open Venue in Maps'));
      await tester.pump();
      expect(find.text('Opening Maps...'), findsOneWidget);
      await tester.tap(find.text('Opening Maps...'));
      await tester.pump();
      expect(calls, 1);

      pending.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Open Venue in Maps'), findsOneWidget);
    });

    testWidgets('shows friendly feedback when launch fails', (tester) async {
      final service = CareerFairMapService(launcher: (_) async => false);
      await tester.pumpWidget(
        app(CareerFairDetailScreen(careerFair: fair(), mapService: service)),
      );

      await tester.scrollUntilVisible(
        find.text('Open Venue in Maps'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Open Venue in Maps'));
      await tester.pumpAndSettle();

      expect(
        find.text('Unable to open this location in Maps.'),
        findsOneWidget,
      );
    });

    testWidgets('copies trimmed address and shows feedback', (tester) async {
      String? copiedAddress;
      await tester.pumpWidget(
        app(
          CareerFairDetailScreen(
            careerFair: fair(address: '  Kuala Lumpur  '),
            addressCopier: (address) async => copiedAddress = address,
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Copy Address'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Copy Address'));
      await tester.pumpAndSettle();

      expect(copiedAddress, 'Kuala Lumpur');
      expect(find.text('Address copied.'), findsOneWidget);
    });

    testWidgets('keeps details, URLs, and list-to-detail navigation', (
      tester,
    ) async {
      final item = fair();
      await tester.pumpWidget(
        app(CareerFairsScreen(repository: _Repository(item))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(item.title));
      await tester.pumpAndSettle();

      expect(find.text(item.description), findsOneWidget);
      expect(find.text(item.address), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(item.sourceUrl!),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(item.registrationUrl!), findsOneWidget);
      expect(find.text(item.sourceUrl!), findsOneWidget);
    });
  });
}

class _Repository implements CareerFairRepository {
  const _Repository(this.item);

  final CareerFair item;

  @override
  Future<CareerFair?> getCareerFairById(String id) async => item;

  @override
  Future<List<CareerFair>> getPastCareerFairs({DateTime? now}) async =>
      const [];

  @override
  Future<List<CareerFair>> getUpcomingCareerFairs({DateTime? now}) async => [
    item,
  ];
}
