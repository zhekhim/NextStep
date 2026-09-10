import 'dart:async';

import 'package:flutter/material.dart';

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
  static const blue = Color(0xFF1A26FF);
  static const card = Color(0xFF181818);
  static const border = Color(0xFF2A2A2A);
  static const secondary = Color(0xFFA8A8A8);

  final _profiles = ProfileRepository();
  final _skillsRepository = SkillRepository();
  final _goals = CareerGoalRepository();
  final _skillGap = SkillGapService();
  late final StreamSubscription<void> _skillChanges;
  late final StreamSubscription<void> _goalChanges;

  bool _loading = true;
  String? _error;
  Profile? _profile;
  CareerGoal? _goal;
  List<UserSkill> _skills = const [];
  double _skillMatch = 0;

  @override
  void initState() {
    super.initState();
    _skillChanges = SkillRepository.skillChanges.listen((_) => _load());
    _goalChanges = CareerGoalRepository.goalChanges.listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _skillChanges.cancel();
    _goalChanges.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final values = await Future.wait([
        _profiles.getCurrentProfile(),
        _skillsRepository.getUserSkills(),
        _goals.getGoal(),
      ]);
      final profile = values[0] as Profile;
      final skills = values[1] as List<UserSkill>;
      final goal = values[2] as CareerGoal?;
      var match = 0.0;
      if (goal != null) {
        final requirements = await _goals.getRequirements(goal.career.id);
        match = _skillGap.matchPercentage(
          _skillGap.compare(requirements, skills),
        );
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _skills = skills;
        _goal = goal;
        _skillMatch = match;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Unable to load your dashboard. Try again.'; _loading = false; });
    }
  }

  double get _goalSetup {
    if (_goal == null) return 0;
    final completed = [
      _goal!.preferredState,
      _goal!.targetGraduationYear,
      _goal!.expectedSalary,
    ].where((value) => value != null).length;
    return completed / 3 * 100;
  }

  double get _readiness => _skillMatch * 0.7 + _goalSetup * 0.3;

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
                Text(
                  '$_greeting, ${_profile!.fullName.split(' ').first}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                const Text('Continue building your career readiness.', style: TextStyle(color: secondary, fontSize: 15)),
                const SizedBox(height: 24),
                _ReadinessCard(score: _readiness, skillMatch: _skillMatch, goalSetup: _goalSetup, hasGoal: _goal != null, onPressed: () => widget.onSelectSection(3)),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Current Career Goal', action: _goal == null ? null : 'View Goal', onPressed: () => widget.onSelectSection(3)),
                const SizedBox(height: 12),
                _GoalCard(goal: _goal, onPressed: () => widget.onSelectSection(3)),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Skill Overview', action: 'View Profile', onPressed: () => widget.onSelectSection(4)),
                const SizedBox(height: 12),
                _SkillsCard(skills: _skills, onAdd: _addSkill),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Assessment'),
                const SizedBox(height: 12),
                _AssessmentCard(onPressed: () => widget.onSelectSection(2)),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Quick Actions'),
                const SizedBox(height: 12),
                _QuickActions(selectSection: widget.onSelectSection, onAddSkill: _addSkill),
              ],
            ),
          ),
  );
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.score, required this.skillMatch, required this.goalSetup, required this.hasGoal, required this.onPressed});
  final double score;
  final double skillMatch;
  final double goalSetup;
  final bool hasGoal;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final status = !hasGoal ? 'Set a goal to calculate readiness' : score >= 75 ? 'Strong progress' : score >= 50 ? 'Building momentum' : 'Getting started';
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.insights_outlined, color: _HomeScreenState.blue), SizedBox(width: 8), Text('Career Readiness', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 18),
        Text('${score.toStringAsFixed(0)}%', style: const TextStyle(color: _HomeScreenState.blue, fontSize: 36, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: score / 100, minHeight: 7, borderRadius: BorderRadius.circular(4), backgroundColor: _HomeScreenState.border, color: _HomeScreenState.blue),
        const SizedBox(height: 10),
        Text(status, style: const TextStyle(color: _HomeScreenState.secondary)),
        if (hasGoal) ...[
          const SizedBox(height: 14),
          Text('70% skill match (${skillMatch.toStringAsFixed(0)}%)  •  30% goal setup (${goalSetup.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
        ],
        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: onPressed, child: const Text('View Readiness'))),
      ]),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.onPressed});
  final CareerGoal? goal;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (goal == null) return _EmptyCard(icon: Icons.flag_outlined, message: 'You have not set a career goal yet.', action: 'Create Career Goal', onPressed: onPressed);
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(goal!.career.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(goal!.career.category, style: const TextStyle(color: _HomeScreenState.secondary)),
      const SizedBox(height: 16),
      _InfoRow(label: 'Preferred state', value: goal!.preferredState ?? 'Not set'),
      _InfoRow(label: 'Graduation year', value: goal!.targetGraduationYear?.toString() ?? 'Not set'),
      _InfoRow(label: 'Status', value: goal!.status),
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
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${skills.length} skill${skills.length == 1 ? '' : 's'} in your portfolio', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: skills.take(6).map((skill) => Chip(label: Text('${skill.skill.name} · ${skill.level}'))).toList()),
      if (skills.length > 6) ...[const SizedBox(height: 10), Text('+${skills.length - 6} more', style: const TextStyle(color: _HomeScreenState.secondary))],
    ]));
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _Card(child: Row(children: [
    const Icon(Icons.assignment_outlined, color: _HomeScreenState.blue, size: 30),
    const SizedBox(width: 14),
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Discover careers that match your interests.', style: TextStyle(fontWeight: FontWeight.w600)), SizedBox(height: 4), Text('Complete the RIASEC career assessment.', style: TextStyle(color: _HomeScreenState.secondary, fontSize: 13))])),
    IconButton(tooltip: 'Take assessment', onPressed: onPressed, icon: const Icon(Icons.arrow_forward)),
  ]));
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
      _QuickAction(icon: Icons.search, label: 'Explore Careers', onPressed: () => selectSection(1)),
      _QuickAction(icon: Icons.add_circle_outline, label: 'Add Skill', onPressed: onAddSkill),
      _QuickAction(icon: Icons.assignment_outlined, label: 'Assessment', onPressed: () => selectSection(2)),
      _QuickAction(icon: Icons.insights_outlined, label: 'Readiness', onPressed: () => selectSection(3)),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: _HomeScreenState.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _HomeScreenState.border)),
      child: Row(children: [Icon(icon, color: _HomeScreenState.blue), const SizedBox(width: 9), Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))]),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onPressed});
  final String title;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500))),
    if (action != null) TextButton(onPressed: onPressed, child: Text(action!)),
  ]);
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _HomeScreenState.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _HomeScreenState.border)),
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
    Icon(icon, color: _HomeScreenState.secondary, size: 34),
    const SizedBox(height: 10),
    Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _HomeScreenState.secondary)),
    const SizedBox(height: 10),
    FilledButton(onPressed: onPressed, child: Text(action)),
  ]));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 13))),
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
      const Icon(Icons.error_outline, color: Color(0xFFFF4D4D), size: 40),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  ));
}
