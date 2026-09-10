import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/career_goal.dart';
import '../repositories/career_goal_repository.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key, this.goal, this.repository});
  final CareerGoal? goal;
  final CareerGoalRepository? repository;

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CareerGoalRepository _repository;
  late final TextEditingController _stateController;
  late final TextEditingController _yearController;
  late final TextEditingController _salaryController;
  List<CareerOption> _careers = const [];
  CareerOption? _career;
  String _status = 'Active';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? CareerGoalRepository();
    _stateController = TextEditingController(
      text: widget.goal?.preferredState ?? '',
    );
    _yearController = TextEditingController(
      text: widget.goal?.targetGraduationYear?.toString() ?? '',
    );
    _salaryController = TextEditingController(
      text: widget.goal?.expectedSalary?.toStringAsFixed(0) ?? '',
    );
    _status = widget.goal?.status ?? 'Active';
    _loadCareers();
  }

  Future<void> _loadCareers() async {
    try {
      final careers = await _repository.getCareers();
      if (!mounted) return;
      setState(() {
        _careers = careers;
        if (widget.goal != null) {
          for (final career in careers) {
            if (career.id == widget.goal!.career.id) {
              _career = career;
              break;
            }
          }
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load careers. Try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repository.saveGoal(
        career: _career!,
        preferredState: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        targetGraduationYear: int.tryParse(_yearController.text),
        expectedSalary: double.tryParse(_salaryController.text),
        status: _status,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save career goal. Try again.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _stateController.dispose();
    _yearController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.goal == null ? 'Create Career Goal' : 'Edit Career Goal',
        ),
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
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      _loadCareers();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<CareerOption>(
                    initialValue: _career,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Target Career',
                      border: OutlineInputBorder(),
                    ),
                    items: _careers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _career = value),
                    validator: (value) =>
                        value == null ? 'Target career is required.' : null,
                  ),
                  if (_career != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Industry: ${_career!.category}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'Preferred State (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Graduation Year (optional)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final year = int.tryParse(value);
                      return year == null || year < DateTime.now().year
                          ? 'Target year cannot be before the current year.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _salaryController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Expected Salary (RM, optional)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final salary = double.tryParse(value);
                      return salary == null || salary <= 0
                          ? 'Expected salary must be greater than 0.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['Active', 'Paused', 'Achieved']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Goal'),
                  ),
                ],
              ),
            ),
    );
  }
}
