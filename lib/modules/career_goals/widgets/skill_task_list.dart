import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/skill_task.dart';
import '../repositories/skill_task_repository.dart';
import '../services/calendar_service.dart';
import '../services/goal_progress_service.dart';
import '../services/goal_notification_service.dart';

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
  final _notificationService = GoalNotificationService.instance;
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
    SkillTask? createdTask;
    try {
      var task = await _repository.addTask(
        goalId: widget.goalId,
        skillId: widget.skillId,
        taskTitle: input.title,
        dueDate: input.dueDate,
        reminderDaysBefore: input.reminderDaysBefore,
      );
      createdTask = task;
      if (input.reminderDaysBefore != null) {
        final notificationId = _notificationService.notificationIdFor(task.id);
        await _notificationService.schedule(
          notificationId: notificationId,
          milestoneTitle: input.title,
          dueDate: input.dueDate,
          daysBefore: input.reminderDaysBefore!,
        );
        task = await _repository.updateTask(
          task: task,
          taskTitle: input.title,
          dueDate: input.dueDate,
          reminderDaysBefore: input.reminderDaysBefore,
          notificationId: notificationId,
        );
      }
      await _load();
      widget.onTasksChanged?.call();
      _showMessage('Milestone added.');
    } on NotificationPermissionDeniedException {
      await _clearStoredReminder(createdTask);
      await _load();
      widget.onTasksChanged?.call();
      _showMessage('Milestone added, but notification permission was denied.');
    } on ReminderTimePassedException {
      await _clearStoredReminder(createdTask);
      await _load();
      widget.onTasksChanged?.call();
      _showMessage(
        'Milestone added, but the selected reminder time has passed.',
      );
    } on PlatformException catch (error) {
      await _clearStoredReminder(createdTask);
      await _load();
      widget.onTasksChanged?.call();
      _showMessage(
        'Milestone added, but reminder scheduling failed (${error.code}).',
      );
    } catch (error, stackTrace) {
      debugPrint('Milestone reminder scheduling failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (createdTask != null) {
        await _clearStoredReminder(createdTask);
        await _load();
        widget.onTasksChanged?.call();
        _showMessage(
          'Milestone added, but reminder failed: ${_shortError(error)}',
        );
      } else {
        _showMessage('Unable to add milestone. Try again.');
      }
    }
  }

  Future<void> _editTask(SkillTask task) async {
    final input = await _showTaskDialog(task: task);
    if (input == null) return;
    var milestoneUpdated = false;
    try {
      final notificationId = input.reminderDaysBefore == null
          ? null
          : task.notificationId ??
                _notificationService.notificationIdFor(task.id);
      await _repository.updateTask(
        task: task,
        taskTitle: input.title,
        dueDate: input.dueDate,
        reminderDaysBefore: input.reminderDaysBefore,
        notificationId: notificationId,
      );
      milestoneUpdated = true;
      if (task.calendarEventId != null) {
        try {
          await _calendarService.updateMilestone(
            eventId: task.calendarEventId!,
            milestoneTitle: input.title,
            dueDate: input.dueDate,
            careerGoalTitle: widget.careerGoalTitle,
          );
        } catch (_) {}
      }
      if (task.notificationId != null) {
        await _notificationService.cancel(task.notificationId!);
      }
      if (input.reminderDaysBefore != null) {
        await _notificationService.schedule(
          notificationId: notificationId!,
          milestoneTitle: input.title,
          dueDate: input.dueDate,
          daysBefore: input.reminderDaysBefore!,
        );
      }
      await _load();
      widget.onTasksChanged?.call();
      _showMessage('Milestone updated.');
    } on NotificationPermissionDeniedException {
      await _clearStoredReminder(
        task,
        title: input.title,
        dueDate: input.dueDate,
      );
      await _load();
      widget.onTasksChanged?.call();
      _showMessage(
        'Milestone updated, but notification permission was denied.',
      );
    } on ReminderTimePassedException {
      await _clearStoredReminder(
        task,
        title: input.title,
        dueDate: input.dueDate,
      );
      await _load();
      widget.onTasksChanged?.call();
      _showMessage(
        'Milestone updated, but the selected reminder time has passed.',
      );
    } on PlatformException catch (error) {
      await _clearStoredReminder(
        task,
        title: input.title,
        dueDate: input.dueDate,
      );
      await _load();
      widget.onTasksChanged?.call();
      _showMessage(
        'Milestone updated, but reminder scheduling failed (${error.code}).',
      );
    } catch (error, stackTrace) {
      debugPrint('Milestone update failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (milestoneUpdated) {
        await _clearStoredReminder(
          task,
          title: input.title,
          dueDate: input.dueDate,
        );
        await _load();
        widget.onTasksChanged?.call();
        _showMessage(
          'Milestone updated, but reminder failed: ${_shortError(error)}',
        );
      } else {
        _showMessage('Unable to update milestone. Try again.');
      }
    }
  }

  Future<void> _setCompleted(SkillTask task, bool completed) async {
    setState(() => _busyTaskId = task.id);
    try {
      await _repository.setTaskCompleted(task: task, isCompleted: completed);
      if (task.notificationId != null) {
        if (completed) {
          await _notificationService.cancel(task.notificationId!);
        } else if (task.reminderDaysBefore != null) {
          await _notificationService.schedule(
            notificationId: task.notificationId!,
            milestoneTitle: task.taskTitle,
            dueDate: task.dueDate,
            daysBefore: task.reminderDaysBefore!,
          );
        }
      }
      await _load();
      widget.onTasksChanged?.call();
    } on NotificationPermissionDeniedException {
      await _clearStoredReminder(task);
      await _load();
      widget.onTasksChanged?.call();
      _showMessage(
        'Milestone reopened, but notification permission was denied.',
      );
    } on ReminderTimePassedException {
      await _clearStoredReminder(task);
      await _load();
      widget.onTasksChanged?.call();
      _showMessage(
        'Milestone reopened without a reminder because its time has passed.',
      );
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
      await _repository.deleteTask(task);
      if (task.calendarEventId != null) {
        try {
          await _calendarService.removeEvent(task.calendarEventId!);
        } catch (_) {}
      }
      if (task.notificationId != null) {
        try {
          await _notificationService.cancel(task.notificationId!);
        } catch (_) {}
      }
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
    try {
      _showMessage('Review the event in Calendar and tap Save.');
      await _calendarService.openMilestoneEditor(
        milestone: task,
        careerGoalTitle: widget.careerGoalTitle,
      );
    } catch (_) {
      _showMessage('Unable to open the calendar event editor. Try again.');
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

  Future<void> _clearStoredReminder(
    SkillTask? task, {
    String? title,
    DateTime? dueDate,
  }) async {
    if (task == null) return;
    try {
      await _repository.updateTask(
        task: task,
        taskTitle: title ?? task.taskTitle,
        dueDate: dueDate ?? task.dueDate,
      );
    } catch (_) {}
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
                  if (task.reminderDaysBefore != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Reminder: ${_reminderLabel(task.reminderDaysBefore)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA8A8A8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: busy ? null : onAddToCalendar,
                    icon: Icon(
                      task.calendarEventId == null
                          ? Icons.event_outlined
                          : Icons.sync_outlined,
                      size: 17,
                    ),
                    label: Text(
                      task.calendarEventId == null
                          ? 'Add to Calendar'
                          : 'Re-add to Calendar',
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
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
  int? _reminderDaysBefore;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.task?.taskTitle ?? '',
    );
    _dueDate = widget.task?.dueDate;
    _reminderDaysBefore = widget.task?.reminderDaysBefore;
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
    if (_reminderDaysBefore != null) {
      final reminderTime = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        9,
      ).subtract(Duration(days: _reminderDaysBefore!));
      if (!reminderTime.isAfter(DateTime.now())) {
        _showMessage('The selected reminder time must be in the future.');
        return;
      }
    }
    Navigator.pop(
      context,
      _TaskInput(_titleController.text.trim(), _dueDate!, _reminderDaysBefore),
    );
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
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _reminderDaysBefore,
            decoration: const InputDecoration(
              labelText: 'Deadline Reminder',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<int?>(value: null, child: Text('None')),
              DropdownMenuItem<int?>(value: 0, child: Text('On due date')),
              DropdownMenuItem<int?>(value: 1, child: Text('1 day before')),
              DropdownMenuItem<int?>(value: 3, child: Text('3 days before')),
              DropdownMenuItem<int?>(value: 7, child: Text('1 week before')),
            ],
            onChanged: (value) => setState(() => _reminderDaysBefore = value),
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
  const _TaskInput(this.title, this.dueDate, this.reminderDaysBefore);
  final String title;
  final DateTime dueDate;
  final int? reminderDaysBefore;
}

String _reminderLabel(int? daysBefore) => switch (daysBefore) {
  0 => 'On due date',
  1 => '1 day before',
  3 => '3 days before',
  7 => '1 week before',
  _ => 'None',
};

String _shortError(Object error) {
  final message = error.toString().replaceAll(RegExp(r'\s+'), ' ');
  return message.length <= 100 ? message : '${message.substring(0, 97)}...';
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
