import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_intelligence/models/career.dart';
import 'package:untitled/modules/career_intelligence/models/career_skill.dart';
import 'package:untitled/modules/career_intelligence/models/career_shortlist.dart';
import 'package:untitled/modules/career_intelligence/models/labour_force_statistic.dart';
import 'package:untitled/modules/career_intelligence/screens/career_detail_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/career_explorer_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/careers_hub_screen.dart';
import 'package:untitled/modules/career_intelligence/screens/labour_market_screen.dart';
import 'package:untitled/modules/career_intelligence/repositories/career_shortlist_repository.dart';
import 'package:untitled/navigation/main_navigation_screen.dart';

void main() {
  const careers = [
    Career(
      id: '1',
      careerName: 'Data Analyst',
      category: 'Data',
      description: 'Analyses data.',
    ),
    Career(
      id: '2',
      careerName: 'Mobile Developer',
      category: 'Software',
      description: 'Builds mobile applications.',
    ),
  ];
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

  Widget app(Widget child) => MaterialApp(home: child);

  group('Careers hub', () {
    testWidgets('displays all five destinations', (tester) async {
      await tester.pumpWidget(app(const CareersHubScreen()));

      for (final title in [
        'Explore Careers',
        'Interested Careers',
        'Career Fairs',
        'Career Interest Types',
        'Malaysia Labour Market',
      ]) {
        await tester.scrollUntilVisible(find.text(title), 100);
        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('opens Explore Careers and Labour Market destinations', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          CareersHubScreen(
            exploreBuilder: (_) => const Scaffold(body: Text('Explore target')),
            labourMarketBuilder: (_) =>
                const Scaffold(body: Text('Labour target')),
          ),
        ),
      );

      await tester.tap(find.text('Explore Careers'));
      await tester.pumpAndSettle();
      expect(find.text('Explore target'), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Malaysia Labour Market'), 100);
      await tester.tap(find.text('Malaysia Labour Market'));
      await tester.pumpAndSettle();
      expect(find.text('Labour target'), findsOneWidget);
    });
  });

  group('Career Explorer', () {
    testWidgets('shows loading and empty states', (tester) async {
      final result = Completer<List<Career>>();
      await tester.pumpWidget(
        app(CareerExplorerScreen(loadCareers: () => result.future)),
      );
      expect(find.text('Loading careers...'), findsOneWidget);

      result.complete(const []);
      await tester.pumpAndSettle();
      expect(find.text('No careers found.'), findsOneWidget);
    });

    testWidgets('shows error and retries', (tester) async {
      var attempts = 0;
      Future<List<Career>> load() async {
        attempts++;
        if (attempts == 1) throw Exception('offline');
        return careers;
      }

      await tester.pumpWidget(app(CareerExplorerScreen(loadCareers: load)));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load careers.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Data Analyst'), findsOneWidget);
      expect(attempts, 2);
    });

    testWidgets('searches and filters careers', (tester) async {
      await tester.pumpWidget(
        app(CareerExplorerScreen(loadCareers: () async => careers)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'mobile');
      await tester.pump();
      expect(find.text('Mobile Developer'), findsOneWidget);
      expect(find.text('Data Analyst'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('All Categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Data').last);
      await tester.pumpAndSettle();
      expect(find.text('Data Analyst'), findsOneWidget);
      expect(find.text('Mobile Developer'), findsNothing);
    });

    testWidgets('opens the selected career detail destination', (tester) async {
      await tester.pumpWidget(
        app(
          CareerExplorerScreen(
            loadCareers: () async => careers,
            careerDetailBuilder: (career) =>
                Scaffold(body: Text('Detail ${career.id}')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Data Analyst'));
      await tester.pumpAndSettle();
      expect(find.text('Detail 1'), findsOneWidget);
    });
  });

  group('Labour Market', () {
    testWidgets('shows loading and empty states', (tester) async {
      final result = Completer<List<LabourForceStatistic>>();
      await tester.pumpWidget(
        app(LabourMarketScreen(loadStatistics: () => result.future)),
      );
      expect(find.text('Loading labour market data...'), findsOneWidget);

      result.complete(const []);
      await tester.pumpAndSettle();
      expect(find.text('No labour market data available.'), findsOneWidget);
    });

    testWidgets('shows an error and retries', (tester) async {
      var attempts = 0;
      Future<List<LabourForceStatistic>> load() async {
        attempts++;
        if (attempts == 1) throw Exception('offline');
        return [statistic];
      }

      await tester.pumpWidget(app(LabourMarketScreen(loadStatistics: load)));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load labour market data.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('June 2026'), findsOneWidget);
      expect(attempts, 2);
    });

    testWidgets('shows statistics, English labels, and attribution', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(LabourMarketScreen(loadStatistics: () async => [statistic])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Employed Persons'), findsOneWidget);
      expect(find.text('Unemployed Persons'), findsOneWidget);
      expect(find.text('Unemployment Rate'), findsOneWidget);
      expect(find.text('Labour Force Participation Rate'), findsOneWidget);
      expect(find.textContaining('data.gov.my'), findsOneWidget);
      expect(
        find.textContaining('Department of Statistics Malaysia'),
        findsOneWidget,
      );
    });
  });

  testWidgets(
    'shared navigation keeps five destinations and opens Careers hub',
    (tester) async {
      await tester.pumpWidget(app(const MainNavigationScreen()));
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      expect(find.text('Home'), findsNWidgets(2));
      expect(find.text('Assessment'), findsOneWidget);
      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      await tester.tap(find.text('Careers'));
      await tester.pumpAndSettle();
      expect(find.byType(CareersHubScreen), findsOneWidget);
    },
  );

  testWidgets('Career Detail keeps required constructor and Goal action', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        CareerDetailScreen(
          career: careers.first,
          loadSkills: (_) async => const <CareerSkill>[],
          shortlistRepository: _EmptyShortlistRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Set This Career as Goal'), findsOneWidget);
  });
}

class _EmptyShortlistRepository implements CareerShortlistRepository {
  @override
  Future<CareerShortlist> addCareer({
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
    required String shortlistId,
    required String? priority,
    required String? notes,
  }) => throw UnimplementedError();
}
