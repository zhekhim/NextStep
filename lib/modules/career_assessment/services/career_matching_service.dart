import 'dart:math';

import '../models/assessment_result.dart';
import '../models/career_assessment_profile.dart';
import '../models/career_match_result.dart';
import 'assessment_scoring_service.dart';

class CareerMatchingService {
  static const double _maximumDifference = 24;

  List<CareerMatchResult> calculateMatches({
    required AssessmentResult assessmentResult,
    required Iterable<CareerAssessmentProfile> careerProfiles,
    int limit = 5,
  }) {
    final matches = careerProfiles.map((profile) {
      var totalDifference = 0.0;
      for (final dimension in AssessmentScoringService.dimensions) {
        final userPercentage = assessmentResult.dimensionScores[dimension] ?? 0;
        final userValue = userPercentage / 20;
        final careerValue = profile.valueForDimension(dimension);
        totalDifference += (userValue - careerValue).abs();
      }

      final percentage = (1 - totalDifference / _maximumDifference) * 100;
      return CareerMatchResult(
        career: profile.career,
        matchPercentage: max(0, min(100, percentage)).toDouble(),
      );
    }).toList();

    matches.sort((a, b) {
      final scoreComparison = b.matchPercentage.compareTo(a.matchPercentage);
      return scoreComparison != 0
          ? scoreComparison
          : a.career.careerName.compareTo(b.career.careerName);
    });
    return matches.take(limit).toList(growable: false);
  }
}
