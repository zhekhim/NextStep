import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_assessment/models/career_assessment_profile.dart';
import 'package:untitled/modules/career_assessment/models/riasec_question.dart';
import 'package:untitled/modules/career_assessment/services/riasec_career_matching_service.dart';
import 'package:untitled/modules/career_assessment/services/riasec_scoring_service.dart';
import 'package:untitled/modules/career_intelligence/models/career.dart';

void main() {
  test('calculates a dimension average and percentage', () {
    const questions = [RiasecQuestion(id: '1', dimension: 'R', activity: 'One'), RiasecQuestion(id: '2', dimension: 'R', activity: 'Two')];
    final result = RiasecScoringService().calculate(questions: questions, answers: {0: 4, 1: 5});
    final realistic = result.rankedScores.firstWhere((score) => score.dimension == 'R');
    expect(realistic.average, 4.5);
    expect(realistic.percentage, 90);
  });

  test('matches profiles with the transparent difference formula', () {
    final result = RiasecResult([for (final dimension in RiasecScoringService.dimensions) RiasecDimensionScore(dimension: dimension, average: 5, percentage: 100)]);
    const career = Career(id: 'career-1', careerName: 'Test Career', category: 'Test', description: 'Test');
    const profile = CareerAssessmentProfile(careerId: 'career-1', dimensionValues: {'R': 5, 'I': 5, 'A': 5, 'S': 5, 'E': 5, 'C': 5});
    final matches = RiasecCareerMatchingService().findTopMatches(result: result, profiles: [profile], careers: [career]);
    expect(matches.single.matchPercentage, 100);
  });
}
