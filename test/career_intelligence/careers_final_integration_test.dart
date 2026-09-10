import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_intelligence/models/career.dart';
import 'package:untitled/modules/career_intelligence/models/career_fair.dart';
import 'package:untitled/modules/career_intelligence/models/career_shortlist.dart';
import 'package:untitled/modules/career_intelligence/models/career_skill.dart';
import 'package:untitled/modules/career_intelligence/models/labour_force_statistic.dart';
import 'package:untitled/modules/career_intelligence/repositories/career_shortlist_repository.dart';
import 'package:untitled/modules/career_intelligence/screens/career_detail_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/career_explorer_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/career_fair_detail_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/careers_hub_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/interested_careers_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/labour_market_screen.dart';

void main() {
  Widget app(Widget child) => MaterialApp(home: child);

  testWidgets('all five Careers Hub destinations open and return normally', (
    tester,
  ) async {
    await _useCompactAndroidSize(tester);
    const routes = {
      'Explore Careers': 'Explore destination',
      'Interested Careers': 'Interested destination',
      'Career Fairs': 'Fairs destination',
      'Career Interest Types': 'Interest types destination',
      'Malaysia Labour Market': 'Labour destination',
    };
    await tester.pumpWidget(
      app(
        CareersHubScreen(
          exploreBuilder: (_) => const _Destination('Explore destination'),
          interestedCareersBuilder: (_) =>
              const _Destination('Interested destination'),
          careerFairsBuilder: (_) => const _Destination('Fairs destination'),
          interestTypesBuilder: (_) =>
              const _Destination('Interest types destination'),
          labourMarketBuilder: (_) => const _Destination('Labour destination'),
        ),
      ),
    );

    for (final route in routes.entries) {
      await tester.scrollUntilVisible(find.text(route.key), 120);
      await tester.tap(find.text(route.key));
      await tester.pumpAndSettle();
      expect(find.text(route.value), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CareersHubScreen), findsOneWidget);
    }
  });

  testWidgets('long career names fit a compact Android screen', (tester) async {
    await _useCompactAndroidSize(tester);
    const career = Career(
      id: 'career-1',
      careerName:
          'Senior Sustainable Infrastructure Data Engineering Specialist',
      category: 'Information and Communications Technology',
      description: 'Career description',
    );

    await tester.pumpWidget(
      app(CareerExplorerScreen(loadCareers: () async => const [career])),
    );
    await tester.pumpAndSettle();

    expect(find.text(career.careerName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long shortlist notes fit a compact Android screen', (
    tester,
  ) async {
    await _useCompactAndroidSize(tester);
    final item = _shortlist();
    final repository = _ShortlistRepository(item);

    await tester.pumpWidget(
      app(InterestedCareersScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text(item.career.careerName), findsOneWidget);
    expect(find.textContaining('A detailed note'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(repository.loadCount, greaterThanOrEqualTo(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Career Detail preserves constructor and skill requirements', (
    tester,
  ) async {
    const career = Career(
      id: 'career-1',
      careerName: 'Data Analyst',
      category: 'Data',
      description: 'Analyses data.',
    );
    const skill = CareerSkill(
      skillId: 'skill-1',
      skillName: 'Data Visualisation',
      category: 'Technical',
      requiredLevel: 'Advanced',
    );

    await tester.pumpWidget(
      app(
        CareerDetailScreen(
          career: career,
          loadSkills: (_) async => const [skill],
          shortlistRepository: _EmptyShortlistRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Data Visualisation'), findsOneWidget);
    expect(find.text('Technical'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.text('Set This Career as Goal'), findsOneWidget);
    expect(find.text('Save to Interested Careers'), findsOneWidget);
  });

  testWidgets('labour statistics fit a compact Android screen', (tester) async {
    await _useCompactAndroidSize(tester);
    final statistic = LabourForceStatistic(
      date: DateTime(2026, 6),
      labourForce: 17000,
      employed: 16450,
      unemployed: 550,
      outsideLabourForce: 7200,
      unemploymentRate: 3.2,
      participationRate: 70.8,
      employmentPopulationRatio: 68.5,
    );

    await tester.pumpWidget(
      app(LabourMarketScreen(loadStatistics: () async => [statistic])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Labour Force Participation Rate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long Career Fair details remain scrollable', (tester) async {
    await _useCompactAndroidSize(tester);
    final fair = CareerFair(
      id: 'fair-1',
      title: 'Graduate Employment and Sustainable Technology Career Fair',
      organiser: 'Malaysian Graduate Employment Partnership Council',
      description: List.filled(
        12,
        'Meet employers and discuss graduate opportunities.',
      ).join(' '),
      eventDate: DateTime(2026, 10, 20),
      venue: 'Convention Centre',
      address: 'Kuala Lumpur, Malaysia',
      createdAt: DateTime.utc(2026, 9, 8),
      updatedAt: DateTime.utc(2026, 9, 8),
    );

    await tester.pumpWidget(app(CareerFairDetailScreen(careerFair: fair)));
    await tester.scrollUntilVisible(
      find.text('Copy Address'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Copy Address'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _useCompactAndroidSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(320, 568));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

CareerShortlist _shortlist() => CareerShortlist(
  id: 'shortlist-1',
  userId: 'user-1',
  career: const Career(
    id: 'career-1',
    careerName: 'Senior Sustainable Infrastructure Engineering Specialist',
    category: 'Engineering',
    description: 'Career description',
  ),
  priority: 'High',
  notes: List.filled(
    10,
    'A detailed note about preparation and required experience.',
  ).join(' '),
  createdAt: DateTime.utc(2026, 9, 8),
  updatedAt: DateTime.utc(2026, 9, 8),
);

class _Destination extends StatelessWidget {
  const _Destination(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(label)),
    body: Center(child: Text('$label screen')),
  );
}

class _ShortlistRepository implements CareerShortlistRepository {
  _ShortlistRepository(this.item);

  final CareerShortlist item;
  int loadCount = 0;

  @override
  Future<CareerShortlist> addCareer({
    String status = 'Interested',
    required String careerId,
    String? priority,
    String? notes,
  }) => throw UnimplementedError();

  @override
  Future<CareerShortlist?> getShortlistForCareer(String careerId) async => item;

  @override
  Future<List<CareerShortlist>> getShortlistedCareers() async {
    loadCount++;
    return [item];
  }

  @override
  Future<void> removeCareer(String shortlistId) async {}

  @override
  Future<CareerShortlist> updateCareer({
    String? status,
    required String shortlistId,
    required String? priority,
    required String? notes,
  }) => throw UnimplementedError();
}

class _EmptyShortlistRepository implements CareerShortlistRepository {
  @override
  Future<CareerShortlist> addCareer({
    String status = 'Interested',
    required String careerId,
    String? priority,
    String? notes,
  }) => throw UnimplementedError();

  @override
  Future<CareerShortlist?> getShortlistForCareer(String careerId) async => null;

  @override
  Future<List<CareerShortlist>> getShortlistedCareers() async => const [];

  @override
  Future<void> removeCareer(String shortlistId) async {}

  @override
  Future<CareerShortlist> updateCareer({
    String? status,
    required String shortlistId,
    required String? priority,
    required String? notes,
  }) => throw UnimplementedError();
}
