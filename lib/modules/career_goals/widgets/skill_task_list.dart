import 'package:flutter/material.dart';

import '../models/skill_task.dart';
import '../repositories/skill_task_repository.dart';
import '../services/calendar_service.dart';
import '../services/goal_progress_service.dart';

class SkillTaskList extends StatefulWidget {
  const SkillTaskList({
    required this.goalId,
    required this.skillId,
    required this.careerGoalTitle,
    this.onTasksChanged,
    super.key,
  });

  final String goalId;
  final String skillId;
  final String careerGoalTitle;
  final VoidCallback? onTasksChanged;

  @override
  State<SkillTaskList> createState() => _SkillTaskListState();
}

class _SkillTaskListState extends State<SkillTaskList> {
  final _repository = SkillTaskRepository();
  final _calendarService = CalendarService();
  List<SkillTask> _tasks = const [];
  bool _loading = true;
  String? _error;
  String? _busyTaskId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SkillTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goalId != widget.goalId ||
        oldWidget.skillId != widget.skillId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await _repository.getTasksForSkill(
        goalId: widget.goalId,
        skillId: widget.skillId,
      );
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load milestones.';
        _loading = false;
      });
    }
  }

  Future<void> _addTask() async {
    final input = await _showTaskDialog();
    if (input == null) return;
    try {
      await _repository.addTask(
        goalId: widget.goalId,
        skillId: widget.skillId,
        taskTitle: input.title,
        dueDate: input.dueDate,
      );
      await _load();
      widget.onTasksChanged?.call();
      _showMessage('Milestone added.');
    } catch (_) {
      _showMessage('Unable to add milestone. Try again.');
    }
  }

  Future<void> _editTask(SkillTask task) async {
    final input = await _showTaskDialog(task: task);
    if (input == null) return;
    try {
      await _repository.updateTask(
        task: task,
        taskTitle: input.title,
        dueDate: input.dueDate,
      );
      if (task.calendarEventId != null) {
        await _calendarService.updateMilestone(
          eventId: task.calendarEventId!,
          milestoneTitle: input.title,
          dueDate: input.dueDate,
          careerGoalTitle: widget.careerGoalTitle,
        );
      }
      await _load();
      widget.onTasksChanged?.call();
      _showMessage('Milestone updated.');
    } catch (_) {
      _showMessage('Unable to update milestone. Try again.');
    }
  }

  Future<void> _setCompleted(SkillTask task, bool completed) async {
    setState(() => _busyTaskId = task.id);
    try {
      await _repository.setTaskCompleted(task: task, isCompleted: completed);
      await _load();
      widget.onTasksChanged?.call();
    } catch (_) {
      _showMessage('Unable to update milestone. Try again.');
    } finally {
      if (mounted) setState(() => _busyTaskId = null);
    }
  }

  Future<void> _deleteTask(SkillTask task) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Milestone?'),
            content: Text(
              'Are you sure you want to delete the milestone\n'
              '"${task.taskTitle}"?',
            ),
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
    setState(() => _busyTaskId = task.id);
    try {
      if (task.calendarEventId != null) {
        await _calendarService.removeEvent(task.calendarEventId!);
      }
      await _repository.deleteTask(task);
      await _load();
      widget.onTasksChanged?.call();
      _showMessage('Milestone deleted.');
    } catch (_) {
      _showMessage('Unable to delete milestone. Try again.');
    } finally {
      if (mounted) setState(() => _busyTaskId = null);
    }
  }

  Future<void> _addToCalendar(SkillTask task) async {
    setState(() => _busyTaskId = task.id);
    String? eventId;
    try {
      eventId = await _calendarService.addMilestone(
        milestone: task,
        careerGoalTitle: widget.careerGoalTitle,
      );
      await _repository.setCalendarEventId(
        task: task,
        calendarEventId: eventId,
      );
      await _load();
      widget.onTasksChanged?.call();
      _showMessage('Milestone added to your calendar.');
    } on CalendarPermissionDeniedException {
      _showMessage('Calendar permission is required to add this milestone.');
    } catch (_) {
      if (eventId != null) {
        try {
          await _calendarService.removeEvent(eventId);
        } catch (_) {}
      }
      _showMessage('Unable to add milestone to calendar. Try again.');
    } finally {
      if (mounted) setState(() => _busyTaskId = null);
    }
  }

  Future<_TaskInput?> _showTaskDialog({SkillTask? task}) async {
    return showDialog<_TaskInput>(
      context: context,
      builder: (context) => _MilestoneDialog(task: task),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 14),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Loading milestones...'),
          ],
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(
          children: [
            const Expanded(child: Text('Unable to load milestones.')),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final completed = _tasks.where((task) => task.isCompleted).length;
    final progress = _tasks.isEmpty ? 0.0 : completed / _tasks.length;
    final planStatus = _tasks.isEmpty
        ? 'Not Started'
        : completed == _tasks.length
        ? 'Completed'
        : 'In Progress';

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFF2A2A2A)),
          const SizedBox(height: 10),
          if (_tasks.isNotEmpty) ...[
            Text(
              '$completed / ${_tasks.length} completed',
              style: const TextStyle(fontSize: 12, color: Color(0xFFA8A8A8)),
            ),
            const SizedBox(height: 3),
            Text(
              'Plan Status: $planStatus',
              style: const TextStyle(fontSize: 12, color: Color(0xFFA8A8A8)),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFF0007CD),
              backgroundColor: const Color(0xFF2A2A2A),
            ),
            const SizedBox(height: 8),
            ..._tasks.map(
              (task) => _TaskRow(
                task: task,
                busy: _busyTaskId == task.id,
                onCompleted: (value) => _setCompleted(task, value),
                onEdit: () => _editTask(task),
                onDelete: () => _deleteTask(task),
                onAddToCalendar: () => _addToCalendar(task),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addTask,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Milestone'),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.busy,
    required this.onCompleted,
    required this.onEdit,
    required this.onDelete,
    required this.onAddToCalendar,
  });

  final SkillTask task;
  final bool busy;
  final ValueChanged<bool> onCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final deadlineState = GoalProgressService().deadlineState(task);
    final (deadlineLabel, deadlineColor) = switch (deadlineState) {
      MilestoneDeadlineState.completed => (
        'Completed',
        const Color(0xFF33D17A),
      ),
      MilestoneDeadlineState.overdue => ('Overdue', const Color(0xFFFF4D4D)),
      MilestoneDeadlineState.dueSoon => ('Due Soon', const Color(0xFFFFCC4D)),
      MilestoneDeadlineState.upcoming => ('Upcoming', const Color(0xFFC8CEFF)),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: busy ? null : (value) => onCompleted(value ?? false),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.taskTitle,
                    style: TextStyle(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted
                          ? const Color(0xFF888888)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    task.isCompleted
                        ? task.completedAt == null
                              ? 'Completed'
                              : 'Completed: ${_formatDate(task.completedAt!.toLocal())}'
                        : 'Due: ${_formatDate(task.dueDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA8A8A8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _DeadlineBadge(label: deadlineLabel, color: deadlineColor),
                  const SizedBox(height: 8),
                  if (task.calendarEventId == null)
                    OutlinedButton.icon(
                      onPressed: busy ? null : onAddToCalendar,
                      icon: const Icon(Icons.event_outlined, size: 17),
                      label: const Text('Add to Calendar'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  else
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 17,
                          color: Color(0xFF33D17A),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Added to Calendar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF33D17A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Edit milestone',
            onPressed: busy ? null : onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: 'Delete milestone',
            onPressed: busy ? null : onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            color: const Color(0xFFFF4D4D),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _MilestoneDialog extends StatefulWidget {
  const _MilestoneDialog({this.task});

  final SkillTask? task;

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.task?.taskTitle ?? '',
    );
    _dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final today = _today();
    final initialDate = _dueDate == null || _dueDate!.isBefore(today)
        ? today
        : _dueDate!;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 20, 12, 31),
    );
    if (selected != null && mounted) {
      setState(() => _dueDate = selected);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      _showMessage('Please select a due date.');
      return;
    }
    if (_dueDate!.isBefore(_today())) {
      _showMessage('Due date cannot be earlier than today.');
      return;
    }
    Navigator.pop(context, _TaskInput(_titleController.text.trim(), _dueDate!));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.task == null ? 'Add Milestone' : 'Edit Milestone'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Milestone Title',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Milestone title is required.'
                : null,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _selectDueDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              _dueDate == null
                  ? 'Select Due Date'
                  : 'Due: ${_formatDate(_dueDate!)}',
            ),
          ),
          if (_dueDate == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Please select a due date.',
                style: TextStyle(fontSize: 12, color: Color(0xFFA8A8A8)),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

class _DeadlineBadge extends StatelessWidget {
  const _DeadlineBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

class _TaskInput {
  const _TaskInput(this.title, this.dueDate);
  final String title;
  final DateTime dueDate;
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
