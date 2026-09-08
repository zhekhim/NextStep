import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_intelligence/models/career.dart';
import 'package:untitled/modules/career_intelligence/models/career_fair.dart';
import 'package:untitled/modules/career_intelligence/models/career_shortlist.dart';
import 'package:untitled/modules/career_intelligence/models/career_skill.dart';
import 'package:untitled/modules/career_intelligence/models/labour_force_statistic.dart';
import 'package:untitled/modules/career_intelligence/repositories/career_fair_repository.dart';
import 'package:untitled/modules/career_intelligence/repositories/career_shortlist_repository.dart';
import 'package:untitled/modules/career_intelligence/screens/career_detail_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/career_explorer_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/career_fairs_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/interested_careers_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/labour_market_screen.dart';
import 'package:untitled/modules/career_intelligence/widgets/career_card.dart';

void main() {
  Widget app(Widget child) => MaterialApp(home: child);

  testWidgets('600 careers support combined search, filter, and clearing', (
    tester,
  ) async {
    final careers = List.generate(
      600,
      (index) => Career(
        id: 'career-$index',
        careerName: 'Career ${index.toString().padLeft(3, '0')}',
        category: index.isEven ? 'Engineering' : 'Technology',
        description: 'Career description $index',
      ),
    );
    await tester.pumpWidget(
      app(CareerExplorerScreen(loadCareers: () async => careers)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Career 598');
    await tester.tap(find.text('All Categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Engineering').last);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(CareerCard),
        matching: find.text('Career 598'),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Career 599');
    await tester.pump();
    expect(find.text('No careers found.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('Career 000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Career Detail renders five unique levelled skills', (
    tester,
  ) async {
    final skills = [
      _skill('1', 'Advanced Skill', 'Advanced'),
      _skill('2', 'Intermediate Skill', 'Intermediate'),
      _skill('3', 'Beginner Skill', 'Beginner'),
      _skill('4', 'Communication Skill', 'Intermediate'),
      _skill(
        '5',
        'Very Long Sustainable Infrastructure Analysis and Reporting Skill',
        'Advanced',
      ),
      _skill('1', 'Advanced Skill', 'Advanced'),
    ];
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      app(
        CareerDetailScreen(
          career: _career,
          loadSkills: (_) async => skills,
          shortlistRepository: _ShortlistRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Advanced Skill'), findsOneWidget);
    expect(find.text('Advanced'), findsNWidgets(2));
    expect(find.text('Intermediate'), findsNWidgets(2));
    expect(find.text('Beginner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing Career Detail skill lookup shows empty fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        CareerDetailScreen(
          career: _career,
          loadSkills: (_) async => const [],
          shortlistRepository: _ShortlistRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No required skills available for this career.'),
      findsOneWidget,
    );
  });

  testWidgets('Interested Career save blocks repeated taps', (tester) async {
    final pending = Completer<CareerShortlist>();
    final repository = _ShortlistRepository(addResult: pending.future);
    await tester.pumpWidget(
      app(
        CareerDetailScreen(
          career: _career,
          loadSkills: (_) async => const [],
          shortlistRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save to Interested Careers'));
    await tester.pump();
    await tester.tap(find.text('Saving...'));
    expect(repository.addCalls, 1);

    pending.complete(_shortlist);
    await tester.pumpAndSettle();
    expect(find.text('Saved to Interested Careers'), findsOneWidget);
  });

  testWidgets('duplicate Interested Career response is handled', (
    tester,
  ) async {
    final repository = _ShortlistRepository(duplicateOnAdd: true);
    await tester.pumpWidget(
      app(
        CareerDetailScreen(
          career: _career,
          loadSkills: (_) async => const [],
          shortlistRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save to Interested Careers'));
    await tester.pumpAndSettle();

    expect(
      find.text('This career is already in your interested careers.'),
      findsOneWidget,
    );
    expect(find.text('Saved to Interested Careers'), findsOneWidget);
  });

  testWidgets('long Interested Careers list supports pull-to-refresh', (
    tester,
  ) async {
    final items = List.generate(
      30,
      (index) => CareerShortlist(
        id: 'shortlist-$index',
        userId: 'user-1',
        career: Career(
          id: 'career-$index',
          careerName: 'Saved Career ${index.toString().padLeft(2, '0')}',
          category: 'Technology',
          description: 'Career description',
        ),
        createdAt: DateTime.utc(2026, 9, 8),
        updatedAt: DateTime.utc(2026, 9, 8),
      ),
    );
    final repository = _ListShortlistRepository(items);
    await tester.pumpWidget(
      app(InterestedCareersScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(repository.loadCount, greaterThanOrEqualTo(2));
  });

  testWidgets('Labour Market changes selected month using injected data', (
    tester,
  ) async {
    final june = _statistic(DateTime(2026, 6), employed: 16000);
    final may = _statistic(DateTime(2026, 5), employed: 15000);
    await tester.pumpWidget(
      app(LabourMarketScreen(loadStatistics: () async => [june, may])),
    );
    await tester.pumpAndSettle();
    expect(find.text('16.00 million'), findsOneWidget);

    await tester.tap(find.text('June 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('May 2026').last);
    await tester.pumpAndSettle();
    expect(find.text('15.00 million'), findsOneWidget);
  });

  testWidgets('same-date Career Fairs remain sorted and open independently', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final national = _fair(
      id: 'national',
      title: 'National Graduate Career Fair 2026',
      startTime: const Duration(hours: 9),
      venue: 'Kuala Lumpur International Convention and Exhibition Centre',
    );
    final myCareerFair = _fair(
      id: 'my-career-fair',
      title: 'MYCareerFair 2026',
    );
    final repository = _CareerFairRepository([myCareerFair, national]);
    await tester.pumpWidget(
      app(
        CareerFairsScreen(
          repository: repository,
          detailBuilder: (fair) =>
              Scaffold(appBar: AppBar(title: Text('Detail ${fair.id}'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.fairs.map((fair) => fair.id), [
      'national',
      'my-career-fair',
    ]);
    expect(find.text(national.title), findsOneWidget);

    await tester.tap(find.text(national.title));
    await tester.pumpAndSettle();
    expect(find.text('Detail national'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text(myCareerFair.title), 150);
    expect(find.text(myCareerFair.title), findsOneWidget);
    await tester.tap(find.text(myCareerFair.title));
    await tester.pumpAndSettle();
    expect(find.text('Detail my-career-fair'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('past same-date fairs put timed events before untimed events', () {
    final timed = _fair(
      id: 'timed',
      title: 'Timed Event',
      startTime: const Duration(hours: 9),
    );
    final untimed = _fair(id: 'untimed', title: 'Untimed Event');
    final fairs = [untimed, timed]
      ..sort(SupabaseCareerFairRepository.comparePast);

    expect(fairs.map((fair) => fair.id), ['timed', 'untimed']);
  });
}

const _career = Career(
  id: 'career-1',
  careerName: 'Data Analyst',
  category: 'Data',
  description: 'Analyses data.',
);

final _shortlist = CareerShortlist(
  id: 'shortlist-1',
  userId: 'user-1',
  career: _career,
  createdAt: DateTime.utc(2026, 9, 8),
  updatedAt: DateTime.utc(2026, 9, 8),
);

CareerSkill _skill(String id, String name, String level) => CareerSkill(
  skillId: id,
  skillName: name,
  category: 'Technical',
  requiredLevel: level,
);

LabourForceStatistic _statistic(DateTime date, {required double employed}) =>
    LabourForceStatistic(
      date: date,
      labourForce: employed + 500,
      employed: employed,
      unemployed: 500,
      outsideLabourForce: 7000,
      unemploymentRate: 3,
      participationRate: 70,
      employmentPopulationRatio: 68,
    );

CareerFair _fair({
  required String id,
  required String title,
  Duration? startTime,
  String venue = 'Convention Centre',
}) => CareerFair(
  id: id,
  title: title,
  organiser: 'Verified Organiser',
  description: 'Verified event description.',
  eventDate: DateTime(2026, 10, 4),
  startTime: startTime,
  venue: venue,
  address: 'Kuala Lumpur, Malaysia',
  createdAt: DateTime.utc(2026, 9, 8),
  updatedAt: DateTime.utc(2026, 9, 8),
);

class _ShortlistRepository implements CareerShortlistRepository {
  _ShortlistRepository({this.addResult, this.duplicateOnAdd = false});

  final Future<CareerShortlist>? addResult;
  final bool duplicateOnAdd;
  int addCalls = 0;
  int lookupCalls = 0;

  @override
  Future<CareerShortlist> addCareer({
    required String careerId,
    String? priority,
    String? notes,
  }) {
    addCalls++;
    if (duplicateOnAdd) {
      throw const DuplicateCareerShortlistException();
    }
    return addResult ?? Future.value(_shortlist);
  }

  @override
  Future<CareerShortlist?> getShortlistForCareer(String careerId) async {
    lookupCalls++;
    return duplicateOnAdd && lookupCalls > 1 ? _shortlist : null;
  }

  @override
  Future<List<CareerShortlist>> getShortlistedCareers() async => const [];

  @override
  Future<void> removeCareer(String shortlistId) async {}

  @override
  Future<CareerShortlist> updateCareer({
    required String shortlistId,
    required String? priority,
    required String? notes,
  }) => throw UnimplementedError();
}

class _CareerFairRepository implements CareerFairRepository {
  _CareerFairRepository(List<CareerFair> fairs)
    : fairs = [...fairs]..sort(SupabaseCareerFairRepository.compareUpcoming);

  final List<CareerFair> fairs;

  @override
  Future<CareerFair?> getCareerFairById(String id) async {
    for (final fair in fairs) {
      if (fair.id == id) return fair;
    }
    return null;
  }

  @override
  Future<List<CareerFair>> getPastCareerFairs({DateTime? now}) async =>
      const [];

  @override
  Future<List<CareerFair>> getUpcomingCareerFairs({DateTime? now}) async => [
    ...fairs,
  ];
}

class _ListShortlistRepository implements CareerShortlistRepository {
  _ListShortlistRepository(this.items);

  final List<CareerShortlist> items;
  int loadCount = 0;

  @override
  Future<CareerShortlist> addCareer({
    required String careerId,
    String? priority,
    String? notes,
  }) => throw UnimplementedError();

  @override
  Future<CareerShortlist?> getShortlistForCareer(String careerId) async => null;

  @override
  Future<List<CareerShortlist>> getShortlistedCareers() async {
    loadCount++;
    return items;
  }

  @override
  Future<void> removeCareer(String shortlistId) async {}

  @override
  Future<CareerShortlist> updateCareer({
    required String shortlistId,
    required String? priority,
    required String? notes,
  }) => throw UnimplementedError();
}
