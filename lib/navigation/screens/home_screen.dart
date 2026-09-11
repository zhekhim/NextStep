import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../modules/career_assessment/models/assessment_profile.dart';
import '../../modules/career_assessment/repositories/assessment_profile_repository.dart';
import '../../modules/career_assessment/services/riasec_career_matching_service.dart';
import '../../modules/career_goals/models/career_goal.dart';
import '../../modules/career_goals/repositories/career_goal_repository.dart';
import '../../modules/career_goals/services/skill_gap_service.dart';
import '../../modules/profile_skills/models/profile.dart';
import '../../modules/profile_skills/models/user_skill.dart';
import '../../modules/profile_skills/repositories/profile_repository.dart';
import '../../modules/profile_skills/repositories/skill_repository.dart';
import '../../modules/profile_skills/screens/add_skill_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSelectSection});

  final ValueChanged<int> onSelectSection;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profiles = ProfileRepository();
  final _skillsRepository = SkillRepository();
  final _goals = CareerGoalRepository();
  final _skillGap = SkillGapService();
  final _assessments = AssessmentProfileRepository();
  final _riasecMatching = RiasecCareerMatchingService();
  late final StreamSubscription<void> _skillChanges;
  late final StreamSubscription<void> _goalChanges;
  late final StreamSubscription<void> _assessmentChanges;

  bool _loading = true;
  String? _error;
  Profile? _profile;
  CareerGoal? _goal;
  List<UserSkill> _skills = const [];
  AssessmentProfile? _assessment;
  double _skillMatch = 0;
  double _riasecAlignment = 0;

  @override
  void initState() {
    super.initState();
    _skillChanges = SkillRepository.skillChanges.listen((_) => _load());
    _goalChanges = CareerGoalRepository.goalChanges.listen((_) => _load());
    _assessmentChanges = AssessmentProfileRepository.assessmentChanges.listen(
      (_) => _load(),
    );
    _load();
  }

  @override
  void dispose() {
    _skillChanges.cancel();
    _goalChanges.cancel();
    _assessmentChanges.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final values = await Future.wait([
        _profiles.getCurrentProfile(),
        _skillsRepository.getUserSkills(),
        _goals.getGoal(),
        _assessments.getLatestResult(),
      ]);
      final profile = values[0] as Profile;
      final skills = values[1] as List<UserSkill>;
      final goal = values[2] as CareerGoal?;
      final assessment = values[3] as AssessmentProfile?;
      var match = 0.0;
      if (goal != null) {
        final requirements = await _goals.getRequirements(goal.career.id);
        match = _skillGap.matchPercentage(
          _skillGap.compare(requirements, skills),
        );
      }
      var alignment = 0.0;
      if (assessment != null && goal?.career.riasecCode != null) {
        alignment = _riasecMatching.alignmentPercentage(
          rankedDimensions: assessment.rankedDimensions,
          careerCode: goal!.career.riasecCode!,
        );
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _skills = skills;
        _goal = goal;
        _assessment = assessment;
        _skillMatch = match;
        _riasecAlignment = alignment;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Unable to load your dashboard. Try again.'; _loading = false; });
    }
  }

  double get _readiness => _skillMatch * 0.7 + _riasecAlignment * 0.3;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _addSkill() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddSkillScreen()),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('NextStep'),
      actions: [
        IconButton(
          tooltip: 'Refresh dashboard',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _ErrorState(message: _error!, onRetry: _load)
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  children: [
                    Icon(
                      DateTime.now().hour >= 18 || DateTime.now().hour < 6
                          ? Icons.nightlight_round
                          : Icons.wb_sunny_rounded,
                      color: DateTime.now().hour >= 18 || DateTime.now().hour < 6
                          ? AppColors.violetLight
                          : AppColors.warning,
                      size: 34,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$_greeting, ${_profile!.fullName.split(' ').first}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Keep going, small steps lead to big opportunities.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                const SizedBox(height: 24),
                _ReadinessCard(score: _readiness, skillMatch: _skillMatch, riasecAlignment: _riasecAlignment, hasGoal: _goal != null, hasAssessment: _assessment != null, onPressed: () => widget.onSelectSection(3)),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Current Career Goal', accent: AppColors.sky, action: _goal == null ? null : 'View Goal', onPressed: () => widget.onSelectSection(3)),
                const SizedBox(height: 12),
                _GoalCard(goal: _goal, onPressed: () => widget.onSelectSection(3)),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Skill Overview', accent: AppColors.cyan, action: 'View Profile', onPressed: () => widget.onSelectSection(4)),
                const SizedBox(height: 12),
                _SkillsCard(skills: _skills, onAdd: _addSkill),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Assessment', accent: AppColors.violetLight),
                const SizedBox(height: 12),
                _AssessmentCard(assessment: _assessment, onPressed: () => widget.onSelectSection(2)),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Quick Actions', accent: AppColors.primaryLight),
                const SizedBox(height: 12),
                _QuickActions(selectSection: widget.onSelectSection, onAddSkill: _addSkill),
              ],
            ),
          ),
  );
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.score, required this.skillMatch, required this.riasecAlignment, required this.hasGoal, required this.hasAssessment, required this.onPressed});
  final double score;
  final double skillMatch;
  final double riasecAlignment;
  final bool hasGoal;
  final bool hasAssessment;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (status, statusColor, statusBackground) = !hasGoal
        ? ('SET A CAREER GOAL', AppColors.textMuted, AppColors.surfaceElevated)
        : score >= 75
        ? ('GOOD PROGRESS', AppColors.success, AppColors.successSoft)
        : score >= 50
        ? ('IN PROGRESS', AppColors.sky, AppColors.primarySoft)
        : ('NEEDS ATTENTION', AppColors.warning, AppColors.warningSoft);
    return _Card(
      color: AppColors.surfaceCard,
      borderColor: AppColors.hairlineStrong,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('CAREER READINESS', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${score.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w600, height: 1)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: statusBackground, borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withValues(alpha: 0.35))),
              child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
          ])),
          _ReadinessRing(score: score),
          const SizedBox(width: 6),
        ]),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: score / 100, minHeight: 3, borderRadius: BorderRadius.circular(3), backgroundColor: AppColors.hairlineStrong, color: AppColors.primaryLight),
        if (hasGoal) ...[
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _ReadinessPart(icon: Icons.layers_outlined, value: skillMatch, label: 'Skill match')),
            const SizedBox(width: 12),
            Expanded(child: _ReadinessPart(icon: Icons.psychology_outlined, value: riasecAlignment, label: hasAssessment ? 'RIASEC alignment' : 'Take assessment')),
          ]),
        ],
        const SizedBox(height: 4),
        TextButton(onPressed: onPressed, child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('View Full Report'), SizedBox(width: 6), Icon(Icons.chevron_right, size: 17)])),
      ]),
    );
  }
}

class _ReadinessPart extends StatelessWidget {
  const _ReadinessPart({required this.icon, required this.value, required this.label});
  final IconData icon;
  final double value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
      child: Icon(icon, color: AppColors.violetLight, size: 21),
    ),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${value.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ])),
  ]);
}

class _ReadinessRing extends StatelessWidget {
  const _ReadinessRing({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 68,
    child: Stack(alignment: Alignment.center, children: [
      SizedBox.square(
        dimension: 58,
        child: CircularProgressIndicator(
          value: score / 100,
          strokeWidth: 7,
          strokeCap: StrokeCap.round,
          backgroundColor: AppColors.hairlineStrong,
          color: AppColors.primary,
        ),
      ),
      Text('${score.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.onPressed});
  final CareerGoal? goal;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (goal == null) return _EmptyCard(icon: Icons.flag_outlined, message: 'You have not set a career goal yet.', action: 'Create Career Goal', onPressed: onPressed);
    return _Card(color: AppColors.surfaceBlue, borderColor: AppColors.sky, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.flag_outlined, color: AppColors.sky, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text(goal!.career.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 4),
      Text(goal!.career.category, style: const TextStyle(color: AppColors.sky)),
      const SizedBox(height: 14),
      const Divider(color: AppColors.hairlineStrong),
      const SizedBox(height: 8),
      _InfoRow(icon: Icons.location_on_outlined, label: 'Preferred state', value: goal!.preferredState ?? 'Not set'),
      _InfoRow(icon: Icons.school_outlined, label: 'Graduation year', value: goal!.targetGraduationYear?.toString() ?? 'Not set'),
    ]));
  }
}

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.skills, required this.onAdd});
  final List<UserSkill> skills;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return _EmptyCard(icon: Icons.psychology_outlined, message: 'No skills added yet.', action: 'Add Skill', onPressed: onAdd);
    return _Card(color: AppColors.surfaceCard, borderColor: AppColors.hairlineStrong, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 38, height: 34, decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.bar_chart_rounded, color: AppColors.primaryLight, size: 24)),
        const SizedBox(width: 10),
        Expanded(child: Text('${skills.length} skill${skills.length == 1 ? '' : 's'} in your portfolio', style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w600))),
        const Icon(Icons.chevron_right, color: AppColors.primaryLight),
      ]),
      const SizedBox(height: 10),
      const Divider(height: 1, color: AppColors.hairlineStrong),
      const SizedBox(height: 10),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 7,
          childAspectRatio: 4.2,
        ),
        itemCount: skills.length > 4 ? 4 : skills.length,
        itemBuilder: (context, index) => _SkillBadge(skill: skills[index]),
      ),
      if (skills.length > 4) ...[const SizedBox(height: 8), Text('+${skills.length - 4} more skills', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))],
    ]));
  }
}

class _SkillBadge extends StatelessWidget {
  const _SkillBadge({required this.skill});

  final UserSkill skill;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (skill.level) {
      'Advanced' => (AppColors.skillAdvancedSoft, AppColors.skillAdvanced),
      'Intermediate' => (AppColors.skillIntermediateSoft, AppColors.skillIntermediate),
      _ => (AppColors.skillBeginnerSoft, AppColors.skillBeginner),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.55)),
      ),
      child: Text(
        '${skill.skill.name} · ${skill.level}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: foreground, fontSize: 10.5, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.assessment, required this.onPressed});
  final AssessmentProfile? assessment;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final result = assessment;
    return _Card(
      color: AppColors.violetSoft,
      borderColor: AppColors.violetLight,
      child: result == null
          ? Row(children: [
              const Icon(Icons.assignment_outlined, color: AppColors.violetLight, size: 30),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Discover careers that match your interests.', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Complete the RIASEC career assessment.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ])),
              IconButton(tooltip: 'Take assessment', onPressed: onPressed, icon: const Icon(Icons.arrow_forward)),
            ])
          : _HomeAssessmentResult(
              assessment: result,
              onRetake: onPressed,
            ),
    );
  }
}

class _HomeAssessmentResult extends StatelessWidget {
  const _HomeAssessmentResult({
    required this.assessment,
    required this.onRetake,
  });

  final AssessmentProfile assessment;
  final VoidCallback onRetake;

  static const _dimensionNames = {
    'R': 'Realistic',
    'I': 'Investigative',
    'A': 'Artistic',
    'S': 'Social',
    'E': 'Enterprising',
    'C': 'Conventional',
  };

  static const _chipColors = [
    AppColors.violetLight,
    Color(0xFF00C7FF),
    Color(0xFF00D7B0),
  ];

  @override
  Widget build(BuildContext context) {
    final date = assessment.createdAt.toLocal();
    final dateText =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final dimensions = assessment.riasecCode.split('');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9B6CFF), Color(0xFF7357FF)],
            ),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'RIASEC RESULT',
                      style: TextStyle(
                        color: Color(0xFFB7C5E2),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Text(
                    'Completed $dateText',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 35,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF9B6CFF), Color(0xFF5B7CFF)],
                        ).createShader(bounds),
                        child: Text(
                          assessment.riasecCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      for (var index = 0; index < dimensions.length; index++) ...[
                        if (index > 0) const SizedBox(width: 7),
                        _HomeRiasecChip(
                          label:
                              _dimensionNames[dimensions[index]] ??
                              dimensions[index],
                          color: _chipColors[index],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetake,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Retake Assessment'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeRiasecChip extends StatelessWidget {
  const _HomeRiasecChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.85)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.selectSection, required this.onAddSkill});
  final ValueChanged<int> selectSection;
  final VoidCallback onAddSkill;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.8,
    children: [
      _QuickAction(icon: Icons.search, label: 'Explore Careers', accent: AppColors.sky, softColor: AppColors.primarySoft, onPressed: () => selectSection(1)),
      _QuickAction(icon: Icons.add_circle_outline, label: 'Add Skill', accent: AppColors.cyan, softColor: AppColors.cyanSoft, onPressed: onAddSkill),
      _QuickAction(icon: Icons.assignment_outlined, label: 'Assessment', accent: AppColors.violetLight, softColor: AppColors.violetSoft, onPressed: () => selectSection(2)),
      _QuickAction(icon: Icons.insights_outlined, label: 'Readiness', accent: AppColors.primaryLight, softColor: AppColors.primarySubtle, onPressed: () => selectSection(3)),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.accent, required this.softColor, required this.onPressed});
  final IconData icon;
  final String label;
  final Color accent;
  final Color softColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: softColor.withValues(alpha: 0.62), borderRadius: BorderRadius.circular(12), border: Border.all(color: accent.withValues(alpha: 0.42))),
      child: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: softColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: accent, size: 20)), const SizedBox(width: 9), Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))]),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.accent = AppColors.primaryLight, this.action, this.onPressed});
  final String title;
  final Color accent;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 4, height: 20, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 9),
    Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500))),
    if (action != null) TextButton(onPressed: onPressed, child: Text(action!)),
  ]);
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.color = AppColors.surfaceCard, this.borderColor = AppColors.hairline});
  final Widget child;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor.withValues(alpha: 0.65))),
    child: child,
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message, required this.action, required this.onPressed});
  final IconData icon;
  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _Card(child: Column(children: [
    Icon(icon, color: AppColors.textSecondary, size: 34),
    const SizedBox(height: 10),
    Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
    const SizedBox(height: 10),
    FilledButton(onPressed: onPressed, child: Text(action)),
  ]));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppColors.sky, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
      Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 40),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  ));
}
