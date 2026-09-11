import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_assessment/models/assessment_profile.dart';
import 'package:untitled/modules/career_assessment/models/riasec_question.dart';
import 'package:untitled/modules/career_assessment/services/riasec_scoring_service.dart';

void main() {
  test(
    'unequal question counts preserve exact percentages through storage',
    () {
      const counts = {'R': 7, 'I': 9, 'A': 8, 'S': 8, 'E': 8, 'C': 8};
      final questions = [
        for (final entry in counts.entries)
          for (var i = 0; i < entry.value; i++)
            RiasecQuestion(
              id: '${entry.key}$i',
              dimension: entry.key,
              activity: 'Question',
            ),
      ];
      final result = RiasecScoringService().calculate(
        questions: questions,
        answers: {for (var i = 0; i < questions.length; i++) i: i % 5 + 1},
      );
      final fields = AssessmentProfile.scoreFields(result);
      expect(fields['realistic'], 18);
      expect(fields['investigative'], 28);
      final profile = AssessmentProfile.fromJson({
        ...fields,
        'id': 'test',
        'created_at': '2026-09-11T00:00:00Z',
        'riasec_code': result.code,
      }, questionCounts: counts);
      for (final score in result.rankedScores) {
        expect(
          profile.percentages[score.dimension],
          closeTo(score.percentage, 0.000001),
        );
      }
      expect(profile.riasecCode, result.code);
    },
  );

  test('stored RIASEC code is preserved when rebuilding a result', () {
    final profile = AssessmentProfile(
      id: 'saved-result',
      createdAt: DateTime(2026, 9, 11),
      riasecCode: 'RIA',
      percentages: const {
        'R': 60,
        'I': 55,
        'A': 50,
        'S': 95,
        'E': 90,
        'C': 85,
      },
    );

    final result = profile.toResult();

    expect(result.code, 'RIA');
    expect(
      result.rankedScores.map((score) => score.dimension),
      ['R', 'I', 'A', 'S', 'E', 'C'],
    );
  });
}
