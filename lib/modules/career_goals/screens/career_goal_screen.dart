import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../profile_skills/models/user_skill.dart';
import '../../profile_skills/repositories/skill_repository.dart';
import '../models/career_goal.dart';
import '../models/career_requirement.dart';
import '../models/skill_task.dart';
import '../repositories/career_goal_repository.dart';
import '../repositories/skill_task_repository.dart';
import '../services/goal_progress_service.dart';
import '../services/skill_gap_service.dart';
import '../widgets/goal_progress_card.dart';
import '../widgets/skill_task_list.dart';
import '../widgets/upcoming_milestones.dart';
import 'add_goal_screen.dart';

class CareerGoalScreen extends StatefulWidget {
  const CareerGoalScreen({super.key});
  @override
  State<CareerGoalScreen> createState() => _CareerGoalScreenState();
}

class _CareerGoalScreenState extends State<CareerGoalScreen> {
  final _repository = CareerGoalRepository();
  late final StreamSubscription<void> _goalChangesSubscription;
  bool _loading = true;
  String? _error;
  CareerGoal? _goal;

  @override
  void initState() {
    super.initState();
    _goalChangesSubscription = CareerGoalRepository.goalChanges.listen((_) {
      if (mounted) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _goalChangesSubscription.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final goal = await _repository.getGoal();
      if (mounted) {
        setState(() {
          _goal = goal;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load your career goal. Try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openForm() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddGoalScreen(goal: _goal, repository: _repository),
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _goal == null ? 'Career goal created.' : 'Career goal updated.',
          ),
        ),
      );
      _load();
    }
  }

  Future<void> _delete() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete career goal?'),
            content: const Text('Your selected career goal will be removed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Color(0xFFFF4D4D)),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await _repository.deleteGoal();
      if (mounted) {
        setState(() => _goal = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Career goal deleted.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete career goal. Try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Career Goal'),
        actions: _goal == null
            ? null
            : [
                IconButton(
                  tooltip: 'Edit goal',
                  onPressed: _openForm,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete goal',
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
      ),
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
          : _goal == null
          ? _EmptyGoal(onCreate: _openForm)
          : _GoalDetails(goal: _goal!),
    );
  }
}

class _EmptyGoal extends StatelessWidget {
  const _EmptyGoal({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.track_changes, size: 56, color: Color(0xFF666666)),
          const SizedBox(height: 20),
          const Text(
            'Set Your Career Goal',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          const Text(
            'Define your target career to unlock skill gap analysis.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFA8A8A8)),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create Career Goal'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0007CD),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GoalDetails extends StatefulWidget {
  const _GoalDetails({required this.goal});
  final CareerGoal goal;

  @override
  State<_GoalDetails> createState() => _GoalDetailsState();
}

class _GoalDetailsState extends State<_GoalDetails> {
  final _skillGapService = SkillGapService();
  final _goalProgressService = GoalProgressService();
  final _skillTaskRepository = SkillTaskRepository();
  late final StreamSubscription<void> _skillChangesSubscription;
  bool _loadingSkillGap = true;
  bool _loadingProgress = true;
  String? _skillGapError;
  String? _progressError;
  String? _selectedSkillId;
  List<SkillGapResult> _skillGaps = const [];
  List<SkillTask> _upcomingMilestones = const [];
  GoalProgress _progress = const GoalProgress(completedCount: 0, totalCount: 0);

  CareerGoal get goal => widget.goal;

  @override
  void initState() {
    super.initState();
    _skillChangesSubscription = SkillRepository.skillChanges.listen((_) {
      if (mounted) _loadSkillGap();
    });
    _loadSkillGap();
    _loadProgress();
  }

  @override
  void dispose() {
    _skillChangesSubscription.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _GoalDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goal.career.id != widget.goal.career.id) {
      _loadSkillGap();
    }
    if (oldWidget.goal.id != widget.goal.id) {
      _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    setState(() {
      _loadingProgress = true;
      _progressError = null;
    });
    try {
      final milestones = await _skillTaskRepository.getTasksForGoal(goal.id);
      if (!mounted) return;
      setState(() {
        _progress = _goalProgressService.calculate(milestones);
        _upcomingMilestones = _goalProgressService.prioritizedUpcoming(
          milestones,
        );
        _loadingProgress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _progressError = 'Unable to load development progress.';
        _loadingProgress = false;
      });
    }
  }

  Future<void> _loadSkillGap() async {
    setState(() {
      _loadingSkillGap = true;
      _skillGapError = null;
    });
    try {
      final values = await Future.wait<Object>([
        CareerGoalRepository().getRequirements(goal.career.id),
        SkillRepository().getUserSkills(),
      ]);
      if (!mounted) return;
      final skillGaps = _skillGapService.compare(
        values[0] as List<CareerRequirement>,
        values[1] as List<UserSkill>,
      );
      setState(() {
        _skillGaps = skillGaps;
        if (!skillGaps.any(
          (gap) => gap.requirement.skillId == _selectedSkillId,
        )) {
          _selectedSkillId = skillGaps.isEmpty
              ? null
              : skillGaps.first.requirement.skillId;
        }
        _loadingSkillGap = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _skillGapError = 'Unable to load skill gap.';
        _loadingSkillGap = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.career.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _StatusBadge(status: goal.status),
              ],
            ),
            const SizedBox(height: 14),
            _Detail(label: 'Target Industry', value: goal.career.category),
            _Detail(
              label: 'Preferred State',
              value: goal.preferredState ?? 'Not set',
            ),
            _Detail(
              label: 'Target Graduation',
              value: goal.targetGraduationYear?.toString() ?? 'Not set',
            ),
            _Detail(
              label: 'Expected Salary',
              value: goal.expectedSalary == null
                  ? 'Not set'
                  : 'RM${goal.expectedSalary!.toStringAsFixed(0)}',
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Development Progress',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 12),
      _buildProgress(),
      const SizedBox(height: 24),
      const Text(
        'Upcoming Milestones',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 12),
      _buildUpcomingMilestones(),
      const SizedBox(height: 24),
      const Text(
        'Skill Gap',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 12),
      _buildSkillGap(),
    ],
  );

  Widget _buildProgress() {
    if (_loadingProgress) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_progressError != null) {
      return _SkillGapMessage(
        message: _progressError!,
        action: OutlinedButton(
          onPressed: _loadProgress,
          child: const Text('Retry'),
        ),
      );
    }
    return GoalProgressCard(progress: _progress);
  }

  Widget _buildUpcomingMilestones() {
    if (_loadingProgress) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_progressError != null) {
      return _SkillGapMessage(
        message: 'Unable to load upcoming milestones.',
        action: OutlinedButton(
          onPressed: _loadProgress,
          child: const Text('Retry'),
        ),
      );
    }
    return UpcomingMilestones(
      milestones: _upcomingMilestones,
      progressService: _goalProgressService,
    );
  }

  Widget _buildSkillGap() {
    if (_loadingSkillGap) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_skillGapError != null) {
      return _SkillGapMessage(
        message: _skillGapError!,
        action: OutlinedButton(
          onPressed: _loadSkillGap,
          child: const Text('Retry'),
        ),
      );
    }
    if (_skillGaps.isEmpty) {
      return const _SkillGapMessage(
        message: 'No required skills available for this career.',
      );
    }

    final satisfied = _skillGaps
        .where((result) => result.status == SkillGapStatus.satisfied)
        .length;
    final percentage = _skillGapService.matchPercentage(_skillGaps);
    final selectedSkill = _skillGaps.firstWhere(
      (gap) => gap.requirement.skillId == _selectedSkillId,
      orElse: () => _skillGaps.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
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
              const SizedBox(height: 4),
              Text('$satisfied / ${_skillGaps.length} skills satisfied'),
              const SizedBox(height: 20),
              _SkillRadarChart(skillGaps: _skillGaps),
              if (_skillGaps.length > _SkillRadarChart.maximumAxes) ...[
                const SizedBox(height: 8),
                Text(
                  'Showing the first ${_SkillRadarChart.maximumAxes} of '
                  '${_skillGaps.length} required skills.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888888),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ChartLegend(label: 'Your Skills', usePrimaryColor: true),
                  SizedBox(width: 20),
                  _ChartLegend(label: 'Required Skills'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Required Skills',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _skillGaps
                .map(
                  (result) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(result.requirement.skillName),
                      selected:
                          result.requirement.skillId ==
                          selectedSkill.requirement.skillId,
                      onSelected: (_) => setState(
                        () => _selectedSkillId = result.requirement.skillId,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _SkillGapRow(
          key: ValueKey(selectedSkill.requirement.skillId),
          goalId: goal.id,
          careerGoalTitle: goal.career.name,
          result: selectedSkill,
          onTasksChanged: _loadProgress,
        ),
      ],
    );
  }
}

class _SkillRadarChart extends StatelessWidget {
  const _SkillRadarChart({required this.skillGaps});

  static const maximumAxes = 8;
  final List<SkillGapResult> skillGaps;

  @override
  Widget build(BuildContext context) {
    final visibleGaps = skillGaps.take(maximumAxes).toList();
    final entryCount = visibleGaps.length < 3 ? 3 : visibleGaps.length;
    final yourValues = <double>[
      ...visibleGaps.map((gap) => _levelValue(gap.currentLevel)),
      ...List<double>.filled(entryCount - visibleGaps.length, 0),
    ];
    final requiredValues = <double>[
      ...visibleGaps.map((gap) => _levelValue(gap.requirement.requiredLevel)),
      ...List<double>.filled(entryCount - visibleGaps.length, 0),
    ];
    final colors = Theme.of(context).colorScheme;
    final yourColor = colors.primary;
    final requiredColor = colors.secondary;
    final labels = visibleGaps
        .map((gap) => _wrapLabel(gap.requirement.skillName))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: SizedBox(
            width: constraints.maxWidth,
            height: 320,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    dataEntries: yourValues
                        .map((value) => RadarEntry(value: value))
                        .toList(),
                    fillColor: yourColor.withValues(alpha: 0.18),
                    borderColor: yourColor,
                    borderWidth: 2.5,
                    entryRadius: 3,
                  ),
                  RadarDataSet(
                    dataEntries: requiredValues
                        .map((value) => RadarEntry(value: value))
                        .toList(),
                    fillColor: requiredColor.withValues(alpha: 0.12),
                    borderColor: requiredColor,
                    borderWidth: 2,
                    entryRadius: 3,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: Color(0xFF444444)),
                radarShape: RadarShape.polygon,
                tickCount: 3,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                tickBorderData: const BorderSide(color: Color(0xFF303030)),
                gridBorderData: const BorderSide(color: Color(0xFF3A3A3A)),
                titlePositionPercentageOffset: 0.18,
                titleTextStyle: const TextStyle(
                  color: Color(0xFFA8A8A8),
                  fontSize: 10,
                ),
                getTitle: (index, angle) {
                  if (index >= visibleGaps.length) {
                    return const RadarChartTitle(text: '');
                  }
                  return RadarChartTitle(
                    text: labels[index],
                    angle: 0,
                  );
                },
                radarTouchData: RadarTouchData(enabled: false),
              ),
              duration: const Duration(milliseconds: 350),
            ),
          ),
        );
      },
    );
  }

  static double _levelValue(String? level) => switch (level) {
    'Beginner' => 1,
    'Intermediate' => 2,
    'Advanced' => 3,
    _ => 0,
  };

  static String _wrapLabel(String label) {
    const maximumLineLength = 16;
    final lines = <String>[];
    var currentLine = '';

    for (final word in label.trim().split(RegExp(r'\s+'))) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ('$currentLine $word'.length <= maximumLineLength) {
        currentLine = '$currentLine $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) lines.add(currentLine);
    return lines.join('\n');
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.label, this.usePrimaryColor = false});

  final String label;
  final bool usePrimaryColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = usePrimaryColor ? colors.primary : colors.secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final active = status == 'Active';
    final color = active ? const Color(0xFF33D17A) : const Color(0xFFA8A8A8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SkillGapRow extends StatelessWidget {
  const _SkillGapRow({
    super.key,
    required this.goalId,
    required this.careerGoalTitle,
    required this.result,
    required this.onTasksChanged,
  });
  final String goalId;
  final String careerGoalTitle;
  final SkillGapResult result;
  final VoidCallback onTasksChanged;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (result.status) {
      SkillGapStatus.satisfied => ('Satisfied', const Color(0xFF33D17A)),
      SkillGapStatus.insufficient => (
        'Needs Improvement',
        const Color(0xFFFFCC4D),
      ),
      SkillGapStatus.missing => ('Missing', const Color(0xFFFF4D4D)),
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.requirement.skillName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('Required Skill Level: ${result.requirement.requiredLevel}'),
          const SizedBox(height: 2),
          Text(
            'Current Skill Level: ${result.currentLevel ?? 'None'}',
            style: const TextStyle(color: Color(0xFFA8A8A8)),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          SkillTaskList(
            goalId: goalId,
            skillId: result.requirement.skillId,
            careerGoalTitle: careerGoalTitle,
            onTasksChanged: onTasksChanged,
          ),
        ],
      ),
    );
  }
}

class _SkillGapMessage extends StatelessWidget {
  const _SkillGapMessage({required this.message, this.action});
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF181818),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF2A2A2A)),
    ),
    child: Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFC8CEFF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
