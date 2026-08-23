import '../models/career_goal.dart';
import '../models/career_requirement.dart';
import '../models/readiness_score.dart';
import 'skill_gap_service.dart';

class ReadinessCalculator {
  static const skillWeight = 0.50;
  static const certificationWeight = 0.20;
  static const learningWeight = 0.15;
  static const industryWeight = 0.15;

  ReadinessScore calculate({
    required CareerGoal goal,
    required List<SkillGapResult> skillGaps,
    double certificationProgress = 0,
    double learningProgress = 0,
  }) {
    final skillMatch = SkillGapService().matchPercentage(skillGaps);
    final industryAlignment = _industryAlignment(goal);

    return ReadinessScore(
      components: [
        ReadinessComponent(
          label: 'Skill Match',
          score: skillMatch,
          weight: skillWeight,
          description: skillGaps.isEmpty
              ? 'No career skill requirements available'
              : 'Skills meeting the selected career requirements',
        ),
        ReadinessComponent(
          label: 'Certification Progress',
          score: _bounded(certificationProgress),
          weight: certificationWeight,
          description: 'No certification progress tracked yet',
        ),
        ReadinessComponent(
          label: 'Learning Progress',
          score: _bounded(learningProgress),
          weight: learningWeight,
          description: 'No learning progress tracked yet',
        ),
        ReadinessComponent(
          label: 'Industry Alignment',
          score: industryAlignment,
          weight: industryWeight,
          description: 'Active goal, industry, and preferred state details',
        ),
      ],
      strongAreas: skillGaps
          .where((gap) => gap.status == SkillGapStatus.satisfied)
          .map((gap) => gap.requirement.skillName)
          .toList(),
      needsImprovement: skillGaps
          .where((gap) => gap.status != SkillGapStatus.satisfied)
          .map((gap) => gap.requirement.skillName)
          .toList(),
    );
  }

  double _industryAlignment(CareerGoal goal) {
    var completed = 0;
    if (goal.status == 'Active') completed++;
    if (goal.career.category.trim().isNotEmpty) completed++;
    if (goal.preferredState?.trim().isNotEmpty ?? false) completed++;
    return completed / 3 * 100;
  }

  double _bounded(double value) => value.clamp(0, 100).toDouble();
}
