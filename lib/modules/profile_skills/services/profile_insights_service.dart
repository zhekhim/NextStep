import '../models/employment_stat.dart';
import '../models/user_skill.dart';

class ProfileInsights {
  const ProfileInsights({required this.market, required this.missingSkills});

  final EmploymentStat market;
  final List<String> missingSkills;
}

class ProfileInsightsService {
  static const _catalog = <EmploymentStat>[
    EmploymentStat(
      career: 'Software Engineer',
      employmentRate: 94.2,
      unemploymentRate: 5.8,
      requiredSkills: ['Python', 'Java', 'C++', 'SQL'],
      outlook: 'Strong demand for software and digital skills.',
    ),
    EmploymentStat(
      career: 'Data Analyst',
      employmentRate: 91.5,
      unemploymentRate: 8.5,
      requiredSkills: ['Python', 'SQL', 'Statistics', 'Excel'],
      outlook: 'Stable demand across business and technology sectors.',
    ),
    EmploymentStat(
      career: 'Project Manager',
      employmentRate: 88.0,
      unemploymentRate: 12.0,
      requiredSkills: ['Project Management', 'Communication', 'Leadership'],
      outlook: 'Transferable coordination skills remain valuable.',
    ),
  ];

  ProfileInsights analyse({
    required List<UserSkill> skills,
    required List<String> targetRoles,
  }) {
    final target = targetRoles.map((item) => item.trim().toLowerCase());
    final market = _catalog.firstWhere(
      (item) => target.contains(item.career.toLowerCase()),
      orElse: () => _catalog.first,
    );
    final owned = skills.map((item) => item.skill.name.toLowerCase()).toSet();
    final missing = market.requiredSkills
        .where((item) => !owned.contains(item.toLowerCase()))
        .toList(growable: false);
    return ProfileInsights(market: market, missingSkills: missing);
  }
}
