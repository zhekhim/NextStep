import '../models/riasec_career_match.dart';
import '../models/career_assessment_profile.dart';
import '../../career_intelligence/models/career.dart';
import 'riasec_scoring_service.dart';

class RiasecCareerMatchingService {
  List<RiasecCareerMatch> findTopMatches({
    required RiasecResult result,
    required List<CareerAssessmentProfile> profiles,
    required List<Career> careers,
    int limit = 5,
  }) {
    final careerById = {for (final career in careers) career.id: career};
    final userValues = {
      for (final score in result.rankedScores)
        score.dimension: score.percentage / 20,
    };
    final matches = profiles.where((profile) => careerById.containsKey(profile.careerId)).map((profile) {
      final totalDifference = RiasecScoringService.dimensions.fold<double>(
        0,
        (sum, dimension) =>
            sum + (userValues[dimension]! - profile.dimensionValues[dimension]!).abs(),
      );
      final percentage = ((1 - totalDifference / 24) * 100).clamp(0, 100).toDouble();
      return RiasecCareerMatch(
        career: careerById[profile.careerId]!,
        matchPercentage: percentage,
      );
    }).toList();

    matches.sort((left, right) {
      final scoreComparison = right.matchPercentage.compareTo(left.matchPercentage);
      return scoreComparison != 0 ? scoreComparison : left.career.careerName.compareTo(right.career.careerName);
    });
    return matches.take(limit).toList(growable: false);
  }

  double alignmentPercentage({
    required List<String> rankedDimensions,
    required String careerCode,
  }) {
    if (rankedDimensions.length != 6 || careerCode.length != 3) return 0;
    const weights = [50.0, 30.0, 20.0];
    var alignment = 0.0;
    for (var index = 0; index < careerCode.length; index++) {
      final userPosition = rankedDimensions.indexOf(careerCode[index]);
      if (userPosition >= 0) {
        final positionDifference = (userPosition - index).abs();
        alignment += weights[index] * (5 - positionDifference) / 5;
      }
    }
    return alignment.clamp(0, 100);
  }
}
