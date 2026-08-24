import 'package:flutter/material.dart';

import '../../profile_skills/models/user_skill.dart';
import '../../profile_skills/repositories/skill_repository.dart';
import '../models/career_goal.dart';
import '../models/career_requirement.dart';
import '../models/readiness_score.dart';
import '../repositories/career_goal_repository.dart';
import '../services/readiness_calculator.dart';
import '../services/skill_gap_service.dart';

class ReadinessScreen extends StatefulWidget {
  const ReadinessScreen({super.key, required this.goal});

  final CareerGoal goal;

  @override
  State<ReadinessScreen> createState() => _ReadinessScreenState();
}

class _ReadinessScreenState extends State<ReadinessScreen> {
  bool _loading = true;
  String? _error;
  ReadinessScore? _score;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>([
        CareerGoalRepository().getRequirements(widget.goal.career.id),
        SkillRepository().getUserSkills(),
      ]);
      final gaps = SkillGapService().compare(
        values[0] as List<CareerRequirement>,
        values[1] as List<UserSkill>,
      );
      if (!mounted) return;
      setState(() {
        _score = ReadinessCalculator().calculate(
          goal: widget.goal,
          skillGaps: gaps,
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to calculate your readiness. Try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Career Readiness')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _ErrorState(message: _error!, onRetry: _load)
        : RefreshIndicator(
            onRefresh: _load,
            child: _ReadinessContent(score: _score!),
          ),
  );
}

class _ReadinessContent extends StatelessWidget {
  const _ReadinessContent({required this.score});

  final ReadinessScore score;

  @override
  Widget build(BuildContext context) {
    final percentage = score.value.round();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        _Panel(
          child: Column(
            children: [
              const _SectionLabel('CAREER READINESS SCORE'),
              const SizedBox(height: 20),
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score.value / 100,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      color: const Color(0xFF1422FF),
                      backgroundColor: const Color(0xFF252525),
                    ),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _StatusBadge(label: score.status),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('SCORE BREAKDOWN'),
              const SizedBox(height: 18),
              ...score.components.map(_ComponentRow.new),
              const Divider(height: 24, color: Color(0xFF292929)),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Final Score',
                      style: TextStyle(color: Color(0xFFA8A8A8)),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Color(0xFF1422FF),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _AreaPanel(
                title: 'STRONG AREAS',
                color: const Color(0xFF33D17A),
                items: score.strongAreas,
                emptyMessage: 'No strong areas yet',
                icon: Icons.check,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AreaPanel(
                title: 'NEEDS IMPROVEMENT',
                color: const Color(0xFFFFA000),
                items: score.needsImprovement,
                emptyMessage: 'No skill gaps found',
                icon: Icons.circle_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Formula: Skill Match 70% + Industry Alignment 30%.',
          style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
        ),
      ],
    );
  }
}

class _ComponentRow extends StatelessWidget {
  const _ComponentRow(this.component);
  final ReadinessComponent component;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: component.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(
                      text: '  weight ${(component.weight * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              component.score.round().toString(),
              style: const TextStyle(
                color: Color(0xFF1A26FF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: component.score / 100,
          minHeight: 4,
          borderRadius: BorderRadius.circular(4),
          color: const Color(0xFF1A26FF),
          backgroundColor: const Color(0xFF292929),
        ),
        const SizedBox(height: 5),
        Text(
          component.description,
          style: const TextStyle(fontSize: 10, color: Color(0xFF777777)),
        ),
      ],
    ),
  );
}

class _AreaPanel extends StatelessWidget {
  const _AreaPanel({
    required this.title,
    required this.color,
    required this.items,
    required this.emptyMessage,
    required this.icon,
  });
  final String title;
  final Color color;
  final List<String> items;
  final String emptyMessage;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(title, color: color),
        const SizedBox(height: 14),
        if (items.isEmpty)
          Text(
            emptyMessage,
            style: const TextStyle(fontSize: 11, color: Color(0xFF777777)),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 13, color: color),
                  const SizedBox(width: 7),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF181818),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFF2A2A2A)),
    ),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.color = const Color(0xFFA8A8A8)});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: color,
      fontSize: 10,
      letterSpacing: 1,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFF282828),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF3A3A3A)),
    ),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: .7,
        color: Color(0xFFB8B8B8),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
