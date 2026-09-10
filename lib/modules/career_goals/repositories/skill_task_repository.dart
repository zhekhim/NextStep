import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/skill_task.dart';

class SkillTaskRepository {
  factory SkillTaskRepository({SupabaseClient? client}) {
    return SkillTaskRepository._(client);
  }

  SkillTaskRepository._(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const AuthException('No signed-in user was found.');
    return id;
  }

  Future<List<SkillTask>> getTasksForSkill({
    required String goalId,
    required String skillId,
  }) async {
    final rows = await _supabase
        .from('skill_tasks')
        .select()
        .eq('user_id', _userId)
        .eq('goal_id', goalId)
        .eq('skill_id', skillId)
        .order('is_completed')
        .order('due_date');
    return rows.map(SkillTask.fromJson).toList();
  }

  Future<List<SkillTask>> getTasksForGoal(String goalId) async {
    final rows = await _supabase
        .from('skill_tasks')
        .select()
        .eq('user_id', _userId)
        .eq('goal_id', goalId)
        .order('is_completed')
        .order('due_date');
    return rows.map(SkillTask.fromJson).toList();
  }

  Future<SkillTask> addTask({
    required String goalId,
    required String skillId,
    required String taskTitle,
    required DateTime dueDate,
    int? reminderDaysBefore,
    int? notificationId,
  }) async {
    final row = await _supabase
        .from('skill_tasks')
        .insert({
          'user_id': _userId,
          'goal_id': goalId,
          'skill_id': skillId,
          'task_title': taskTitle.trim(),
          'due_date': _dateOnly(dueDate),
          'is_completed': false,
          'completed_at': null,
          'calendar_event_id': null,
          'reminder_days_before': reminderDaysBefore,
          'notification_id': notificationId,
        })
        .select()
        .single();
    return SkillTask.fromJson(row);
  }

  Future<SkillTask> updateTask({
    required SkillTask task,
    required String taskTitle,
    required DateTime dueDate,
    int? reminderDaysBefore,
    int? notificationId,
  }) async {
    final row = await _supabase
        .from('skill_tasks')
        .update({
          'task_title': taskTitle.trim(),
          'due_date': _dateOnly(dueDate),
          'reminder_days_before': reminderDaysBefore,
          'notification_id': notificationId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', task.id)
        .eq('user_id', _userId)
        .eq('goal_id', task.goalId)
        .eq('skill_id', task.skillId)
        .select()
        .single();
    return SkillTask.fromJson(row);
  }

  Future<SkillTask> setTaskCompleted({
    required SkillTask task,
    required bool isCompleted,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final row = await _supabase
        .from('skill_tasks')
        .update({
          'is_completed': isCompleted,
          'completed_at': isCompleted ? now : null,
          'updated_at': now,
        })
        .eq('id', task.id)
        .eq('user_id', _userId)
        .eq('goal_id', task.goalId)
        .eq('skill_id', task.skillId)
        .select()
        .single();
    return SkillTask.fromJson(row);
  }

  Future<SkillTask> setCalendarEventId({
    required SkillTask task,
    required String calendarEventId,
  }) async {
    final row = await _supabase
        .from('skill_tasks')
        .update({
          'calendar_event_id': calendarEventId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', task.id)
        .eq('user_id', _userId)
        .eq('goal_id', task.goalId)
        .select()
        .single();
    return SkillTask.fromJson(row);
  }

  Future<void> deleteTask(SkillTask task) async {
    await _supabase
        .from('skill_tasks')
        .delete()
        .eq('id', task.id)
        .eq('user_id', _userId)
        .eq('goal_id', task.goalId)
        .eq('skill_id', task.skillId);
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
