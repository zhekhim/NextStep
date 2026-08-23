import 'package:flutter/material.dart';

import '../../profile_skills/models/user_skill.dart';
import '../../profile_skills/repositories/skill_repository.dart';
import '../models/career_goal.dart';
import '../models/career_requirement.dart';
import '../repositories/career_goal_repository.dart';
import '../services/skill_gap_service.dart';

class SkillGapScreen extends StatefulWidget {
  const SkillGapScreen({super.key, required this.goal});
  final CareerGoal goal;

  @override
  State<SkillGapScreen> createState() => _SkillGapScreenState();
}

class _SkillGapScreenState extends State<SkillGapScreen> {
  bool _loading = true;
  String? _error;
  List<SkillGapResult> _results = const [];
  final _service = SkillGapService();

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
      if (!mounted) return;
      setState(() {
        _results = _service.compare(
          values[0] as List<CareerRequirement>,
          values[1] as List<UserSkill>,
        );
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to calculate your skill gap. Try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final satisfied = _results
        .where((r) => r.status == SkillGapStatus.satisfied)
        .length;
    final percentage = _service.matchPercentage(_results);
    return Scaffold(
      appBar: AppBar(title: const Text('Skill Gap Analysis')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : _results.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No skill requirements are available for this career yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.goal.career.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A26FF),
                        ),
                      ),
                      Text('$satisfied / ${_results.length} skills satisfied'),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF0007CD),
                        backgroundColor: const Color(0xFF2A2A2A),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ..._results.map((result) => _SkillRow(result: result)),
              ],
            ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.result});
  final SkillGapResult result;

  @override
  Widget build(BuildContext context) {
    final label = switch (result.status) {
      SkillGapStatus.satisfied => 'Satisfied',
      SkillGapStatus.insufficient => 'Insufficient',
      SkillGapStatus.missing => 'Missing',
    };
    final color = switch (result.status) {
      SkillGapStatus.satisfied => const Color(0xFF33D17A),
      SkillGapStatus.insufficient => const Color(0xFFFFCC4D),
      SkillGapStatus.missing => const Color(0xFFFF4D4D),
    };
    return Card(
      color: const Color(0xFF181818),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.requirement.skillName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Required: ${result.requirement.requiredLevel}'),
                  Text(
                    'Current: ${result.currentLevel ?? 'Not Added'}',
                    style: const TextStyle(color: Color(0xFFA8A8A8)),
                  ),
                ],
              ),
            ),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
