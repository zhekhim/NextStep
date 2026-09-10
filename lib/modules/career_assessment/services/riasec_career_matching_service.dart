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
}
