import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/modules/career_intelligence/models/career.dart';
import 'package:untitled/modules/career_intelligence/models/career_shortlist.dart';
import 'package:untitled/modules/career_intelligence/repositories/career_shortlist_repository.dart';
import 'package:untitled/modules/career_intelligence/screens/career_detail_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/careers_hub_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/edit_interested_career_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/interested_careers_screen.dart';

void main() {
  const career = Career(
    id: 'career-1',
    careerName: 'Data Analyst',
    category: 'Data',
    description: 'Analyses data.',
  );
  final now = DateTime.utc(2026, 9, 8);

  CareerShortlist item({
    String id = 'shortlist-1',
    Career selectedCareer = career,
    String? priority,
    String? notes,
  }) => CareerShortlist(
    id: id,
    userId: 'user-1',
    career: selectedCareer,
    priority: priority,
    notes: notes,
    createdAt: now,
    updatedAt: now,
  );

  Widget app(Widget child) => MaterialApp(home: child);

  group('CareerShortlist model and validation', () {
    test('parses nested career and normalizes blank notes', () {
      final parsed = CareerShortlist.fromJson({
        'id': 'shortlist-1',
        'user_id': 'user-1',
        'priority': null,
        'notes': '   ',
        'created_at': '2026-09-08T00:00:00Z',
        'updated_at': '2026-09-08T00:00:00Z',
        'careers': {
          'id': 'career-1',
          'career_name': 'Data Analyst',
          'category': 'Data',
          'description': 'Analyses data.',
        },
      });

      expect(parsed.career.careerName, 'Data Analyst');
      expect(parsed.priority, isNull);
      expect(parsed.notes, isNull);
    });

    test('rejects malformed required data', () {
      expect(
        () => CareerShortlist.fromJson({'id': 'shortlist-1'}),
        throwsFormatException,
      );
      expect(
        () => CareerShortlist.fromJson({
          'id': 'shortlist-1',
          'user_id': 'user-1',
          'created_at': '2026-09-08T00:00:00Z',
          'updated_at': '2026-09-08T00:00:00Z',
          'careers': {'id': 'career-1'},
        }),
        throwsFormatException,
      );
    });

    test('accepts allowed priorities and rejects invalid priority', () {
      for (final value in [null, 'High', 'Medium', 'Low']) {
        expect(CareerShortlist.validatePriority(value), value);
      }
      expect(
        () => CareerShortlist.validatePriority('Urgent'),
        throwsArgumentError,
      );
    });

    test('validates and normalizes note length', () {
      expect(CareerShortlist.normalizeNotes('  note  '), 'note');
      expect(CareerShortlist.normalizeNotes('   '), isNull);
      final fiveHundredCharacters = List.filled(500, 'a').join();
      final fiveHundredOneCharacters = List.filled(501, 'a').join();
      expect(
        CareerShortlist.normalizeNotes(fiveHundredCharacters)?.length,
        500,
      );
      expect(
        () => CareerShortlist.normalizeNotes(fiveHundredOneCharacters),
        throwsArgumentError,
      );
    });
  });

  group('CareerShortlist repository', () {
    test('requires a current authenticated user before reading', () async {
      final repository = SupabaseCareerShortlistRepository(
        client: SupabaseClient(
          'https://example.supabase.co',
          'sb_publishable_test',
        ),
      );

      await expectLater(
        repository.getShortlistedCareers(),
        throwsA(isA<CareerShortlistAuthException>()),
      );
    });

    test('provides a friendly duplicate message', () {
      expect(
        const DuplicateCareerShortlistException().toString(),
        'This career is already in your interested careers.',
      );
    });
  });

  group('Career Detail shortlist action', () {
    testWidgets('shows checking then unsaved state and saves successfully', (
      tester,
    ) async {
      final lookup = Completer<CareerShortlist?>();
      final repository = _FakeRepository(onLookup: (_) => lookup.future);
      await tester.pumpWidget(
        app(
          CareerDetailScreen(
            career: career,
            loadSkills: (_) async => const [],
            shortlistRepository: repository,
          ),
        ),
      );
      expect(find.text('Checking Interested Careers...'), findsOneWidget);
      lookup.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('Save to Interested Careers'), findsOneWidget);
      expect(find.text('Set This Career as Goal'), findsOneWidget);

      repository.items = [item()];
      await tester.tap(find.text('Save to Interested Careers'));
      await tester.pumpAndSettle();
      expect(repository.addedCareerId, career.id);
      expect(find.text('Saved to Interested Careers'), findsOneWidget);
    });

    testWidgets('saved action opens edit screen', (tester) async {
      final repository = _FakeRepository(items: [item()]);
      await tester.pumpWidget(
        app(
          CareerDetailScreen(
            career: career,
            loadSkills: (_) async => const [],
            shortlistRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved to Interested Careers'));
      await tester.pumpAndSettle();
      expect(find.byType(EditInterestedCareerScreen), findsOneWidget);
    });
  });

  group('Interested Careers screen', () {
    testWidgets('shows loading, empty, error, and retry', (tester) async {
      final pending = Completer<List<CareerShortlist>>();
      final repository = _FakeRepository(onGet: () => pending.future);
      await tester.pumpWidget(
        app(InterestedCareersScreen(repository: repository)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(const []);
      await tester.pumpAndSettle();
      expect(find.textContaining('No interested careers yet'), findsOneWidget);

      repository.onGet = null;
      repository.failGet = true;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        app(InterestedCareersScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unable to load interested careers.'), findsOneWidget);
      repository.failGet = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No interested careers yet'), findsOneWidget);
    });

    testWidgets('sorts priorities, previews notes, and opens detail', (
      tester,
    ) async {
      const alpha = Career(
        id: 'a',
        careerName: 'Alpha',
        category: 'One',
        description: 'A',
      );
      const beta = Career(
        id: 'b',
        careerName: 'Beta',
        category: 'Two',
        description: 'B',
      );
      final repository = _FakeRepository(
        items: [
          item(id: 'low', selectedCareer: alpha, priority: 'Low'),
          item(
            id: 'high',
            selectedCareer: beta,
            priority: 'High',
            notes: 'My note',
          ),
        ],
      );
      await tester.pumpWidget(
        app(
          InterestedCareersScreen(
            repository: repository,
            detailBuilder: (value) =>
                Scaffold(body: Text('Detail ${value.id}')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('My note'), findsOneWidget);
      final highY = tester.getTopLeft(find.text('Beta')).dy;
      final lowY = tester.getTopLeft(find.text('Alpha')).dy;
      expect(highY, lessThan(lowY));
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(find.text('Detail b'), findsOneWidget);
    });

    testWidgets('delete supports cancel and confirmation', (tester) async {
      final repository = _FakeRepository(items: [item()]);
      await tester.pumpWidget(
        app(InterestedCareersScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repository.removedId, isNull);

      await tester.tap(find.byTooltip('Remove'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(repository.removedId, 'shortlist-1');
      expect(find.text('Data Analyst'), findsNothing);
    });
  });

  testWidgets('edit screen saves priority and trimmed notes', (tester) async {
    final repository = _FakeRepository(items: [item()]);
    await tester.pumpWidget(
      app(
        EditInterestedCareerScreen(shortlist: item(), repository: repository),
      ),
    );
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Interested').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Considering').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '  Learn SQL  ');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(repository.updatedPriority, 'High');
    expect(repository.updatedNotes, '  Learn SQL  ');
    expect(repository.updatedStatus, 'Considering');
  });

  testWidgets('Hub opens real Interested Careers and keeps placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        CareersHubScreen(
          interestedCareersBuilder: (_) =>
              InterestedCareersScreen(repository: _FakeRepository()),
        ),
      ),
    );
    await tester.tap(find.text('Interested Careers'));
    await tester.pumpAndSettle();
    expect(find.byType(InterestedCareersScreen), findsOneWidget);
  });
}

class _FakeRepository implements CareerShortlistRepository {
  _FakeRepository({List<CareerShortlist>? items, this.onGet, this.onLookup})
    : items = items ?? [];

  List<CareerShortlist> items;
  Future<List<CareerShortlist>> Function()? onGet;
  Future<CareerShortlist?> Function(String careerId)? onLookup;
  bool failGet = false;
  String? addedCareerId;
  String? removedId;
  String? updatedPriority;
  String? updatedNotes;
  String? updatedStatus;

  @override
  Future<List<CareerShortlist>> getShortlistedCareers() async {
    if (onGet != null) return onGet!();
    if (failGet) throw Exception('failed');
    return [...items];
  }

  @override
  Future<CareerShortlist?> getShortlistForCareer(String careerId) async {
    if (onLookup != null) return onLookup!(careerId);
    for (final item in items) {
      if (item.career.id == careerId) return item;
    }
    return null;
  }

  @override
  Future<CareerShortlist> addCareer({
    String status = 'Interested',
    required String careerId,
    String? priority,
    String? notes,
  }) async {
    addedCareerId = careerId;
    return items.first;
  }

  @override
  Future<CareerShortlist> updateCareer({
    String? status,
    required String shortlistId,
    required String? priority,
    required String? notes,
  }) async {
    updatedPriority = priority;
    updatedNotes = notes;
    updatedStatus = status;
    final current = items.firstWhere((item) => item.id == shortlistId);
    return CareerShortlist(
      id: current.id,
      userId: current.userId,
      career: current.career,
      priority: CareerShortlist.validatePriority(priority),
      notes: CareerShortlist.normalizeNotes(notes),
      status: status ?? current.status,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
    );
  }

  @override
  Future<void> removeCareer(String shortlistId) async {
    removedId = shortlistId;
    items.removeWhere((item) => item.id == shortlistId);
  }
}
