import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_assessment/services/assessment_report_service.dart';
import 'package:untitled/modules/career_assessment/services/riasec_scoring_service.dart';
import 'package:untitled/modules/career_intelligence/models/career_shortlist.dart';

void main() {
  test('generates a PDF from a completed assessment', () async {
    final bytes = await AssessmentReportService().generate(
      result: RiasecResult([
        for (final dimension in RiasecScoringService.dimensions)
          RiasecDimensionScore(
            dimension: dimension,
            average: 3,
            percentage: 50,
            totalScore: 24,
            questionCount: 8,
          ),
      ]),
      careers: [],
      dimensions: {},
      generatedAt: DateTime.utc(2026, 9, 11),
    );
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test('saved careers require one of the three interest statuses', () {
    for (final value in ['Interested', 'Considering', 'Not Interested']) {
      expect(CareerShortlist.validateStatus(value), value);
    }
    expect(() => CareerShortlist.validateStatus(''), throwsArgumentError);
    expect(() => CareerShortlist.validateStatus('Other'), throwsArgumentError);
  });
}
