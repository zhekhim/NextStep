import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_assessment/models/riasec_question.dart';
import 'package:untitled/modules/career_assessment/services/riasec_career_matching_service.dart';
import 'package:untitled/modules/career_assessment/services/riasec_scoring_service.dart';

void main() {
  final service = RiasecScoringService();

  test('counts every response and applies both tie breakers', () {
    const valuesByDimension = {
      'R': [5, 5, 3, 3, 2, 2, 2, 2],
      'I': [5, 4, 3, 3, 3, 2, 2, 2],
      'A': [1, 1, 1, 1, 1, 1, 1, 1],
      'S': [1, 1, 1, 1, 1, 1, 1, 1],
      'E': [1, 1, 1, 1, 1, 1, 1, 1],
      'C': [5, 4, 4, 3, 2, 2, 2, 2],
    };
    final questions = <RiasecQuestion>[];
    final answers = <int, int>{};
    for (final dimension in RiasecScoringService.dimensions) {
      for (final value in valuesByDimension[dimension]!) {
        answers[questions.length] = value;
        questions.add(
          RiasecQuestion(dimension: dimension, activity: 'Test activity'),
        );
      }
    }

    final result = service.calculate(questions: questions, answers: answers);

    expect(result.code, 'RCI');
    expect(result.rankedScores.first.total, 24);
    expect(result.rankedScores[1].total, 24);
    expect(result.rankedScores[2].total, 24);
  });

  test('always produces a three-character code for a complete tie', () {
    final questions = <RiasecQuestion>[];
    final answers = <int, int>{};
    for (final dimension in RiasecScoringService.dimensions) {
      for (var count = 0; count < 8; count++) {
        answers[questions.length] = 3;
        questions.add(
          RiasecQuestion(dimension: dimension, activity: 'Test activity'),
        );
      }
    }

    final result = service.calculate(questions: questions, answers: answers);

    expect(result.code, 'RIA');
    expect(result.code.length, 3);
  });

  test('career matcher returns five recommendations', () {
    final result = RiasecResult([
      const RiasecDimensionScore(
        dimension: 'I',
        total: 36,
        enjoyCount: 4,
        slightlyEnjoyCount: 3,
      ),
      const RiasecDimensionScore(
        dimension: 'C',
        total: 33,
        enjoyCount: 3,
        slightlyEnjoyCount: 3,
      ),
      const RiasecDimensionScore(
        dimension: 'R',
        total: 30,
        enjoyCount: 2,
        slightlyEnjoyCount: 4,
      ),
      const RiasecDimensionScore(
        dimension: 'E',
        total: 25,
        enjoyCount: 1,
        slightlyEnjoyCount: 3,
      ),
      const RiasecDimensionScore(
        dimension: 'S',
        total: 22,
        enjoyCount: 1,
        slightlyEnjoyCount: 2,
      ),
      const RiasecDimensionScore(
        dimension: 'A',
        total: 18,
        enjoyCount: 0,
        slightlyEnjoyCount: 2,
      ),
    ]);

    final matches = RiasecCareerMatchingService().findTopMatches(result);

    expect(matches, hasLength(5));
    expect(matches.first.riasecCode, 'ICR');
  });
}
