import '../models/riasec_career_match.dart';
import 'riasec_scoring_service.dart';

class RiasecCareerMatchingService {
  static const _careers = [
    ('Software Developer', 'IRC', 'Build and improve software systems.'),
    ('Data Analyst', 'ICE', 'Turn data into useful business insights.'),
    ('Cybersecurity Analyst', 'ICR', 'Protect systems, networks, and data.'),
    ('Research Scientist', 'IRA', 'Investigate questions through research.'),
    ('Civil Engineer', 'RIC', 'Design and develop physical infrastructure.'),
    ('Electrical Engineer', 'RIC', 'Develop and maintain electrical systems.'),
    ('Mechanical Engineer', 'RIC', 'Design machines and mechanical solutions.'),
    ('UX Designer', 'AIR', 'Design useful and accessible digital experiences.'),
    ('Graphic Designer', 'AER', 'Communicate ideas through visual design.'),
    (
      'Content Strategist',
      'AES',
      'Plan creative content for target audiences.',
    ),
    ('Architect', 'AIR', 'Combine creative design with technical planning.'),
    ('Teacher', 'SAI', 'Help learners develop knowledge and skills.'),
    ('Counsellor', 'SIA', 'Support people through personal challenges.'),
    ('Nurse', 'SIR', 'Provide practical care and health support.'),
    (
      'Human Resources Specialist',
      'SEC',
      'Support people and workplace operations.',
    ),
    ('Marketing Manager', 'EAS', 'Lead campaigns and market strategy.'),
    ('Entrepreneur', 'ECR', 'Create and manage new business opportunities.'),
    ('Sales Manager', 'ESC', 'Lead teams and develop customer relationships.'),
    ('Project Manager', 'ECR', 'Coordinate people, resources, and delivery.'),
    ('Accountant', 'CIE', 'Organise and analyse financial information.'),
    ('Auditor', 'CIE', 'Review records, controls, and compliance.'),
    (
      'Administrative Executive',
      'CSE',
      'Coordinate records and office processes.',
    ),
    ('Financial Analyst', 'ICE', 'Evaluate financial data and opportunities.'),
  ];

  List<RiasecCareerMatch> findTopMatches(RiasecResult result, {int limit = 5}) {
    final userOrder = result.rankedScores
        .map((score) => score.dimension)
        .toList(growable: false);
    final matches = _careers.map((career) {
      var score = 0;
      for (var position = 0; position < career.$2.length; position++) {
        final dimension = career.$2[position];
        final userPosition = userOrder.indexOf(dimension);
        score += (6 - userPosition) * 10;
        if (userPosition == position) score += 15;
      }
      return RiasecCareerMatch(
        careerName: career.$1,
        riasecCode: career.$2,
        description: career.$3,
        matchScore: score,
      );
    }).toList();

    matches.sort((left, right) {
      final scoreComparison = right.matchScore.compareTo(left.matchScore);
      return scoreComparison != 0
          ? scoreComparison
          : left.careerName.compareTo(right.careerName);
    });
    return matches.take(limit).toList(growable: false);
  }
}
