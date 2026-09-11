import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_assessment/models/assessment_profile.dart';
import 'package:untitled/modules/career_assessment/models/riasec_question.dart';
import 'package:untitled/modules/career_assessment/screens/riasec_test_screen.dart';

void main() {
  Widget app({AssessmentProfile? latestResult}) => MaterialApp(
    home: RiasecTestScreen(
      loadQuestions: () async => _questions,
      loadLatestResult: () async => latestResult,
    ),
  );

  testWidgets('history is available before starting an assessment', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('View Assessment History'), findsOneWidget);
    expect(find.text('View Latest Result & Recommendations'), findsNothing);
  });

  testWidgets('latest recommendations are available for a returning user', (
    tester,
  ) async {
    await tester.pumpWidget(app(latestResult: _latestResult));
    await tester.pumpAndSettle();

    expect(find.text('View Assessment History'), findsOneWidget);
    expect(find.text('View Latest Result & Recommendations'), findsOneWidget);
  });
}

final _questions = [
  for (var dimensionIndex = 0; dimensionIndex < 6; dimensionIndex++)
    for (var questionIndex = 0; questionIndex < 8; questionIndex++)
      RiasecQuestion(
        id: '$dimensionIndex-$questionIndex',
        dimension: const ['R', 'I', 'A', 'S', 'E', 'C'][dimensionIndex],
        activity: 'Assessment activity',
      ),
];

final _latestResult = AssessmentProfile(
  id: 'saved-result',
  createdAt: DateTime(2026, 9, 11),
  riasecCode: 'RIA',
  percentages: const {
    'R': 90,
    'I': 80,
    'A': 70,
    'S': 60,
    'E': 50,
    'C': 40,
  },
);
