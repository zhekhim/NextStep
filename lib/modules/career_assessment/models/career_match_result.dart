import '../../career_intelligence/models/career.dart';

class CareerMatchResult {
  const CareerMatchResult({
    required this.career,
    required this.matchPercentage,
  });

  final Career career;
  final double matchPercentage;
}
