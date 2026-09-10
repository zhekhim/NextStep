import '../../career_intelligence/models/career.dart';

class RiasecCareerMatch {
  const RiasecCareerMatch({
    required this.career,
    required this.matchPercentage,
  });

  final Career career;
  final double matchPercentage;
}
