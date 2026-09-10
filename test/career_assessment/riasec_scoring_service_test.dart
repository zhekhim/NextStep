import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_assessment/models/career_assessment_profile.dart';
import 'package:untitled/modules/career_assessment/models/riasec_question.dart';
import 'package:untitled/modules/career_assessment/services/riasec_career_matching_service.dart';
import 'package:untitled/modules/career_assessment/services/riasec_scoring_service.dart';
import 'package:untitled/modules/career_intelligence/models/career.dart';

void main() {
  test('calculates a dimension average and percentage', () {
    final questions = _questions();
    final answers = _answers(
      questions,
      overrides: {
        'R': [4, 5, 3, 4, 5, 4, 3, 4],
      },
    );
    final result = RiasecScoringService().calculate(
      questions: questions,
      answers: answers,
    );
    final realistic = result.rankedScores.firstWhere(
      (score) => score.dimension == 'R',
    );
    expect(realistic.totalScore, 32);
    expect(realistic.average, 4);
    expect(realistic.percentage, 75);
  });

  test('uses response counts and fixed RIASEC order to break ties', () {
    final questions = _questions();
    final answers = _answers(
      questions,
      overrides: {
        'R': [5, 5, 3, 3, 3, 3, 3, 3],
        'I': [5, 4, 4, 3, 3, 3, 3, 3],
      },
    );
    final result = RiasecScoringService().calculate(
      questions: questions,
      answers: answers,
    );

    expect(result.rankedScores[0].dimension, 'R');
    expect(result.rankedScores[1].dimension, 'I');
    expect(result.rankedScores.skip(2).map((score) => score.dimension), [
      'A',
      'S',
      'E',
      'C',
    ]);
  });

  test('allows different question counts between dimensions', () {
    final questions = _questions();
    questions[0] = const RiasecQuestion(
      id: 'I-extra',
      dimension: 'I',
      activity: 'Extra investigative question',
    );
    final answers = _answers(questions);

    final result = RiasecScoringService().calculate(
      questions: questions,
      answers: answers,
    );

    expect(result.rankedScores, hasLength(6));
    expect(
      result.rankedScores.firstWhere((score) => score.dimension == 'R').average,
      3,
    );
    expect(
      result.rankedScores.firstWhere((score) => score.dimension == 'I').average,
      3,
    );
  });

  test('matches profiles with the transparent difference formula', () {
    final result = RiasecResult([
      for (final dimension in RiasecScoringService.dimensions)
        RiasecDimensionScore(dimension: dimension, average: 5, percentage: 100),
    ]);
    const career = Career(
      id: 'career-1',
      careerName: 'Test Career',
      category: 'Test',
      description: 'Test',
    );
    const profile = CareerAssessmentProfile(
      careerId: 'career-1',
      dimensionValues: {'R': 5, 'I': 5, 'A': 5, 'S': 5, 'E': 5, 'C': 5},
    );
    final matches = RiasecCareerMatchingService().findTopMatches(
      result: result,
      profiles: [profile],
      careers: [career],
    );
    expect(matches.single.matchPercentage, 100);
  });

  test('RIASEC alignment weights the career code in priority order', () {
    final alignment = RiasecCareerMatchingService().alignmentPercentage(
      rankedDimensions: const ['I', 'C', 'E', 'R', 'S', 'A'],
      careerCode: 'ICE',
    );

    expect(alignment, 100);
  });
}

List<RiasecQuestion> _questions() {
  return [
    for (final dimension in RiasecScoringService.dimensions)
      for (var index = 0; index < 8; index++)
        RiasecQuestion(
          id: '$dimension-$index',
          dimension: dimension,
          activity: '$dimension question ${index + 1}',
        ),
  ];
}

Map<int, int> _answers(
  List<RiasecQuestion> questions, {
  Map<String, List<int>> overrides = const {},
}) {
  final usedByDimension = <String, int>{};
  return {
    for (var index = 0; index < questions.length; index++)
      index: () {
        final dimension = questions[index].dimension;
        final dimensionIndex = usedByDimension[dimension] ?? 0;
        usedByDimension[dimension] = dimensionIndex + 1;
        return overrides[dimension]?[dimensionIndex] ?? 3;
      }(),
  };
}
