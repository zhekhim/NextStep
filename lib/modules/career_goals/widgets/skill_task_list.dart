import 'package:flutter/material.dart';

import '../models/skill_task.dart';
import '../repositories/skill_task_repository.dart';

class SkillTaskList extends StatefulWidget {
  const SkillTaskList({required this.goalId, required this.skillId, super.key});

  final String goalId;
  final String skillId;

  @override
  State<SkillTaskList> createState() => _SkillTaskListState();
}

class _SkillTaskListState extends State<SkillTaskList> {
  final _repository = SkillTaskRepository();
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
        _error = 'Unable to load tasks.';
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
      _showMessage('Task added.');
    } catch (_) {
      _showMessage('Unable to add task. Try again.');
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
      await _load();
      _showMessage('Task updated.');
    } catch (_) {
      _showMessage('Unable to update task. Try again.');
    }
  }

  Future<void> _setCompleted(SkillTask task, bool completed) async {
    setState(() => _busyTaskId = task.id);
    try {
      await _repository.setTaskCompleted(task: task, isCompleted: completed);
      await _load();
    } catch (_) {
      _showMessage('Unable to update task. Try again.');
    } finally {
      if (mounted) setState(() => _busyTaskId = null);
    }
  }

  Future<void> _deleteTask(SkillTask task) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task?'),
            content: Text(
              'Are you sure you want to delete\n"${task.taskTitle}"?',
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
      await _repository.deleteTask(task);
      await _load();
      _showMessage('Task deleted.');
    } catch (_) {
      _showMessage('Unable to delete task. Try again.');
    } finally {
      if (mounted) setState(() => _busyTaskId = null);
    }
  }

  Future<_TaskInput?> _showTaskDialog({SkillTask? task}) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: task?.taskTitle ?? '');
    DateTime? dueDate = task?.dueDate;
    final result = await showDialog<_TaskInput>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(task == null ? 'Add Development Task' : 'Edit Task'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Task title is required.'
                      : null,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final today = _today();
                    final initialDate =
                        dueDate == null || dueDate!.isBefore(today)
                        ? today
                        : dueDate!;
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: today,
                      lastDate: DateTime(today.year + 20, 12, 31),
                    );
                    if (selected != null && context.mounted) {
                      setDialogState(() => dueDate = selected);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    dueDate == null
                        ? 'Select Due Date'
                        : 'Due: ${_formatDate(dueDate!)}',
                  ),
                ),
                if (dueDate == null)
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
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                if (dueDate == null) {
                  _showDialogMessage('Please select a due date.');
                  return;
                }
                if (dueDate!.isBefore(_today())) {
                  _showDialogMessage('Due date cannot be earlier than today.');
                  return;
                }
                Navigator.pop(
                  context,
                  _TaskInput(titleController.text.trim(), dueDate!),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    return result;
  }

  void _showDialogMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
            Text('Loading tasks...'),
          ],
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(
          children: [
            const Expanded(child: Text('Unable to load tasks.')),
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
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addTask,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Task'),
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
  });

  final SkillTask task;
  final bool busy;
  final ValueChanged<bool> onCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
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
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Edit task',
          onPressed: busy ? null : onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          tooltip: 'Delete task',
          onPressed: busy ? null : onDelete,
          icon: const Icon(Icons.delete_outline, size: 18),
          color: const Color(0xFFFF4D4D),
          visualDensity: VisualDensity.compact,
        ),
      ],
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
