import 'dart:async';

import 'package:flutter/material.dart';

import '../models/career_goal.dart';
import '../repositories/career_goal_repository.dart';
import 'add_goal_screen.dart';
import 'readiness_screen.dart';
import 'skill_gap_screen.dart';

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
            'Define your target career to unlock skill gap analysis and readiness tracking.',
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

class _GoalDetails extends StatelessWidget {
  const _GoalDetails({required this.goal});
  final CareerGoal goal;

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
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _NavigationCard(
              icon: Icons.search,
              title: 'Skill Gap',
              description: 'See what skills you need',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SkillGapScreen(goal: goal)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _NavigationCard(
              icon: Icons.track_changes,
              title: 'Readiness',
              description: 'Check your readiness score',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReadinessScreen(goal: goal)),
              ),
            ),
          ),
        ],
      ),
    ],
  );
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

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF181818),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: Color(0xFF2A2A2A)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1A26FF)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Color(0xFFA8A8A8)),
            ),
          ],
        ),
      ),
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
