import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_intelligence/models/career_fair.dart';
import 'package:untitled/modules/career_intelligence/repositories/career_fair_repository.dart';
import 'package:untitled/modules/career_intelligence/screens/career_fair_detail_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/career_fairs_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/careers_hub_screen.dart';
import 'package:untitled/modules/career_intelligence/services/career_fair_formatter.dart';

void main() {
  Map<String, dynamic> record({
    Object? startTime = '09:00:00',
    Object? endTime = '17:00:00',
    Object? latitude = '3.1390',
    Object? longitude = 101.6869,
    Object? registrationUrl = 'https://example.com/register',
    Object? sourceUrl = 'https://example.com/source',
  }) => {
    'id': 'fair-1',
    'title': 'Verified Career Fair',
    'organiser': 'Verified Organiser',
    'description': 'A verified recruitment event.',
    'event_date': '2026-10-20',
    'start_time': startTime,
    'end_time': endTime,
    'venue': 'Convention Centre',
    'address': 'Kuala Lumpur, Malaysia',
    'latitude': latitude,
    'longitude': longitude,
    'registration_url': registrationUrl,
    'source_url': sourceUrl,
    'created_at': '2026-09-08T00:00:00Z',
    'updated_at': '2026-09-08T00:00:00Z',
  };

  CareerFair fair({
    String id = 'fair-1',
    String title = 'Verified Career Fair',
    DateTime? date,
    Duration? start = const Duration(hours: 9),
    Duration? end = const Duration(hours: 17),
    String? registrationUrl = 'https://example.com/register',
    String? sourceUrl = 'https://example.com/source',
  }) => CareerFair(
    id: id,
    title: title,
    organiser: 'Verified Organiser',
    description: 'A verified recruitment event.',
    eventDate: date ?? DateTime(2026, 10, 20),
    startTime: start,
    endTime: end,
    venue: 'Convention Centre',
    address: 'Kuala Lumpur, Malaysia',
    latitude: 3.139,
    longitude: 101.6869,
    registrationUrl: registrationUrl,
    sourceUrl: sourceUrl,
    createdAt: DateTime.utc(2026, 9, 8),
    updatedAt: DateTime.utc(2026, 9, 8),
  );

  Widget app(Widget child) => MaterialApp(home: child);

  group('CareerFair model', () {
    test('parses a complete record and coordinate strings', () {
      final parsed = CareerFair.fromJson(record());
      expect(parsed.title, 'Verified Career Fair');
      expect(parsed.eventDate, DateTime(2026, 10, 20));
      expect(parsed.startTime, const Duration(hours: 9));
      expect(parsed.endTime, const Duration(hours: 17));
      expect(parsed.hasCoordinates, isTrue);
      expect(parsed.hasUsableLocation, isTrue);
    });

    test('supports no time, start only, URLs, or coordinates', () {
      final noOptional = CareerFair.fromJson(
        record(
          startTime: '',
          endTime: null,
          latitude: null,
          longitude: null,
          registrationUrl: ' ',
          sourceUrl: null,
        ),
      );
      expect(noOptional.startTime, isNull);
      expect(noOptional.endTime, isNull);
      expect(noOptional.registrationUrl, isNull);
      expect(noOptional.sourceUrl, isNull);
      expect(noOptional.hasCoordinates, isFalse);

      final startOnly = CareerFair.fromJson(record(endTime: null));
      expect(startOnly.startTime, const Duration(hours: 9));
      expect(startOnly.endTime, isNull);
    });

    test('rejects partial or invalid coordinates', () {
      expect(
        () => CareerFair.fromJson(record(longitude: null)),
        throwsFormatException,
      );
      expect(
        () => CareerFair.fromJson(record(latitude: 91)),
        throwsFormatException,
      );
      expect(
        () => CareerFair.fromJson(record(longitude: -181)),
        throwsFormatException,
      );
    });

    test('rejects blank required values', () {
      final invalid = record()..['venue'] = '   ';
      expect(() => CareerFair.fromJson(invalid), throwsFormatException);
    });
  });

  group('Malaysia date and sorting', () {
    test('converts UTC to the Malaysian calendar date', () {
      expect(
        SupabaseCareerFairRepository.malaysiaToday(
          DateTime.utc(2026, 9, 8, 16, 30),
        ),
        DateTime(2026, 9, 9),
      );
    });

    test('upcoming and past boundary includes Malaysia today', () {
      final today = SupabaseCareerFairRepository.malaysiaToday(
        DateTime.utc(2026, 9, 8, 16, 30),
      );
      expect(DateTime(2026, 9, 8).isBefore(today), isTrue);
      expect(DateTime(2026, 9, 9).isBefore(today), isFalse);
      expect(DateTime(2026, 9, 10).isBefore(today), isFalse);
    });

    test('sorts upcoming by date, time, null time, then title', () {
      final fairs = [
        fair(id: 'null', title: 'Null', start: null, end: null),
        fair(id: 'late', title: 'Late', start: const Duration(hours: 14)),
        fair(id: 'alpha', title: 'Alpha', start: const Duration(hours: 9)),
        fair(id: 'beta', title: 'Beta', start: const Duration(hours: 9)),
        fair(id: 'first', date: DateTime(2026, 10, 19)),
      ]..sort(SupabaseCareerFairRepository.compareUpcoming);
      expect(fairs.map((value) => value.id), [
        'first',
        'alpha',
        'beta',
        'late',
        'null',
      ]);
    });

    test('sorts past by descending date and time', () {
      final fairs = [
        fair(id: 'older', date: DateTime(2026, 10, 18)),
        fair(id: 'morning', start: const Duration(hours: 9)),
        fair(id: 'afternoon', start: const Duration(hours: 14)),
      ]..sort(SupabaseCareerFairRepository.comparePast);
      expect(fairs.map((value) => value.id), ['afternoon', 'morning', 'older']);
    });

    test('formats supported time combinations', () {
      expect(CareerFairFormatter.time(const Duration(hours: 9)), '9:00 AM');
      expect(
        CareerFairFormatter.time(const Duration(hours: 14, minutes: 30)),
        '2:30 PM',
      );
      expect(
        CareerFairFormatter.timeRange(fair(start: null, end: null)),
        'Time not specified',
      );
      expect(CareerFairFormatter.timeRange(fair(end: null)), '9:00 AM');
      expect(CareerFairFormatter.timeRange(fair()), '9:00 AM – 5:00 PM');
    });
  });

  group('Career Fairs screens', () {
    testWidgets('shows loading, empty, error, and retry', (tester) async {
      final pending = Completer<List<CareerFair>>();
      final repository = _FakeCareerFairRepository(
        onLoad: () => pending.future,
      );
      await tester.pumpWidget(app(CareerFairsScreen(repository: repository)));
      expect(find.text('Loading career fairs...'), findsOneWidget);
      pending.complete(const []);
      await tester.pumpAndSettle();
      expect(
        find.text('No upcoming career fairs are currently available.'),
        findsOneWidget,
      );

      repository.onLoad = null;
      repository.fail = true;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(CareerFairsScreen(repository: repository)));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load career fairs.'), findsOneWidget);
      repository.fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Upcoming Career Fairs'), findsOneWidget);
    });

    testWidgets('shows card content, refreshes, and opens detail', (
      tester,
    ) async {
      final repository = _FakeCareerFairRepository(items: [fair()]);
      await tester.pumpWidget(
        app(
          CareerFairsScreen(
            repository: repository,
            detailBuilder: (value) =>
                Scaffold(body: Text('Detail ${value.id}')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Verified Career Fair'), findsOneWidget);
      expect(find.text('Verified Organiser'), findsOneWidget);
      expect(find.text('Convention Centre'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(repository.loadCount, greaterThanOrEqualTo(2));

      await tester.tap(find.text('Verified Career Fair'));
      await tester.pumpAndSettle();
      expect(find.text('Detail fair-1'), findsOneWidget);
    });

    testWidgets('detail displays fields, time, URLs, and no-time fallback', (
      tester,
    ) async {
      await tester.pumpWidget(app(CareerFairDetailScreen(careerFair: fair())));
      expect(find.text('Verified Career Fair'), findsOneWidget);
      expect(find.text('20 October 2026'), findsOneWidget);
      expect(find.text('9:00 AM – 5:00 PM'), findsOneWidget);
      expect(find.text('Kuala Lumpur, Malaysia'), findsOneWidget);
      expect(find.text('Registration'), findsOneWidget);
      expect(find.text('Verified Source'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        app(
          CareerFairDetailScreen(
            careerFair: fair(
              start: null,
              end: null,
              registrationUrl: null,
              sourceUrl: null,
            ),
          ),
        ),
      );
      expect(find.text('Time not specified'), findsOneWidget);
      expect(find.text('Registration'), findsNothing);
      expect(find.text('Verified Source'), findsNothing);
    });

    testWidgets('Hub opens the real Career Fairs screen', (tester) async {
      await tester.pumpWidget(
        app(
          CareersHubScreen(
            careerFairsBuilder: (_) =>
                CareerFairsScreen(repository: _FakeCareerFairRepository()),
          ),
        ),
      );
      await tester.scrollUntilVisible(find.text('Career Fairs'), 100);
      await tester.tap(find.text('Career Fairs'));
      await tester.pumpAndSettle();
      expect(find.byType(CareerFairsScreen), findsOneWidget);
    });
  });
}

class _FakeCareerFairRepository implements CareerFairRepository {
  _FakeCareerFairRepository({List<CareerFair>? items, this.onLoad})
    : items = items ?? [];

  List<CareerFair> items;
  Future<List<CareerFair>> Function()? onLoad;
  bool fail = false;
  int loadCount = 0;

  @override
  Future<List<CareerFair>> getUpcomingCareerFairs({DateTime? now}) async {
    loadCount++;
    if (onLoad != null) return onLoad!();
    if (fail) throw Exception('failed');
    return [...items];
  }

  @override
  Future<List<CareerFair>> getPastCareerFairs({DateTime? now}) async =>
      const [];

  @override
  Future<CareerFair?> getCareerFairById(String id) async {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
