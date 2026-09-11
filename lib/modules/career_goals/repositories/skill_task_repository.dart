import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/local_database.dart';
import '../models/skill_task.dart';

class SkillTaskRepository {
  factory SkillTaskRepository({
    SupabaseClient? client,
    LocalCache? cache,
    String? userId,
  }) {
    return SkillTaskRepository._(
      client,
      cache ?? LocalDatabase.instance,
      userId,
    );
  }

  SkillTaskRepository._(this._client, this._cache, this._userIdOverride);

  final SupabaseClient? _client;
  final LocalCache _cache;
  final String? _userIdOverride;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  String get _userId {
    final override = _userIdOverride;
    if (override != null) return override;
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const AuthException('No signed-in user was found.');
    return id;
  }

  Future<List<SkillTask>> getTasksForSkill({
    required String goalId,
    required String skillId,
  }) async {
    final userId = _userId;
    try {
      final rows = await _supabase
          .from('skill_tasks')
          .select()
          .eq('user_id', userId)
          .eq('goal_id', goalId)
          .eq('skill_id', skillId)
          .order('is_completed', ascending: true)
          .order('due_date', ascending: true)
          .order('created_at', ascending: true);
      final tasks = rows.map(SkillTask.fromJson).toList(growable: false);
      await _cacheTasksForSkill(userId, goalId, skillId, tasks);
      return tasks;
    } catch (_) {
      final rows = await _cache.readTasksForSkill(userId, goalId, skillId);
      return rows.map(SkillTask.fromJson).toList(growable: false);
    }
  }

  Future<List<SkillTask>> getCachedTasksForSkill({
    required String goalId,
    required String skillId,
  }) async {
    final rows = await _cache.readTasksForSkill(_userId, goalId, skillId);
    return rows.map(SkillTask.fromJson).toList(growable: false);
  }

  Future<List<SkillTask>> getTasksForGoal(String goalId) async {
    final userId = _userId;
    try {
      final rows = await _supabase
          .from('skill_tasks')
          .select()
          .eq('user_id', userId)
          .eq('goal_id', goalId)
          .order('is_completed', ascending: true)
          .order('due_date', ascending: true)
          .order('created_at', ascending: true);
      final tasks = rows.map(SkillTask.fromJson).toList(growable: false);
      try {
        await _cache.replaceTasksForGoal(
          userId,
          goalId,
          tasks.map((task) => task.toCacheRow()).toList(),
        );
      } catch (_) {
        // Online tasks remain usable if the optional cache cannot be updated.
      }
      return tasks;
    } catch (_) {
      final rows = await _cache.readTasksForGoal(userId, goalId);
      return rows.map(SkillTask.fromJson).toList(growable: false);
    }
  }

  Future<List<SkillMilestoneTemplate>> getRecommendedTemplates({
    required String skillId,
    required String? currentLevel,
    required String requiredLevel,
  }) async {
    const ranks = {'Beginner': 1, 'Intermediate': 2, 'Advanced': 3};
    final currentRank = ranks[currentLevel] ?? 0;
    final requiredRank = ranks[requiredLevel] ?? 1;
    if (currentRank >= requiredRank) return const [];

    List<SkillMilestoneTemplate> templates;
    try {
      final rows = await _supabase
          .from('skill_milestone_templates')
          .select()
          .eq('skill_id', skillId)
          .order('milestone_order');
      templates = rows
          .map(SkillMilestoneTemplate.fromJson)
          .toList(growable: false);
      try {
        await _cache.replaceMilestoneTemplates(
          skillId,
          templates.map((template) => template.toCacheRow()).toList(),
        );
      } catch (_) {
        // Templates from Supabase remain usable if local caching fails.
      }
    } catch (_) {
      final rows = await _cache.readMilestoneTemplates(skillId);
      if (rows.isEmpty) rethrow;
      templates = rows
          .map(SkillMilestoneTemplate.fromJson)
          .toList(growable: false);
    }
    return _filterTemplates(templates, currentRank, requiredRank);
  }

  Future<List<SkillMilestoneTemplate>> getCachedRecommendedTemplates({
    required String skillId,
    required String? currentLevel,
    required String requiredLevel,
  }) async {
    const ranks = {'Beginner': 1, 'Intermediate': 2, 'Advanced': 3};
    final currentRank = ranks[currentLevel] ?? 0;
    final requiredRank = ranks[requiredLevel] ?? 1;
    if (currentRank >= requiredRank) return const [];
    final rows = await _cache.readMilestoneTemplates(skillId);
    final templates = rows
        .map(SkillMilestoneTemplate.fromJson)
        .toList(growable: false);
    return _filterTemplates(templates, currentRank, requiredRank);
  }

  List<SkillMilestoneTemplate> _filterTemplates(
    List<SkillMilestoneTemplate> templates,
    int currentRank,
    int requiredRank,
  ) {
    const ranks = {'Beginner': 1, 'Intermediate': 2, 'Advanced': 3};
    return templates
        .where((template) {
          final rank = ranks[template.targetLevel] ?? 0;
          return rank > currentRank && rank <= requiredRank;
        })
        .toList(growable: false);
  }

  Future<void> addRecommendedPlan({
    required String goalId,
    required String skillId,
    required List<SkillMilestoneTemplate> templates,
  }) async {
    var dueDate = DateTime.now();
    final rows = <Map<String, dynamic>>[];
    for (final template in templates) {
      dueDate = dueDate.add(Duration(days: template.suggestedDurationDays));
      rows.add({
        'user_id': _userId,
        'goal_id': goalId,
        'skill_id': skillId,
        'template_id': template.id,
        'task_title': template.title,
        'description': template.description,
        'completion_evidence': template.completionEvidence,
        'due_date': _dateOnly(dueDate),
        'is_completed': false,
      });
    }
    if (rows.isNotEmpty) {
      await _supabase.from('skill_tasks').insert(rows);
      await getTasksForSkill(goalId: goalId, skillId: skillId);
    }
  }

  Future<SkillTask> addTask({
    required String goalId,
    required String skillId,
    required String taskTitle,
    required DateTime dueDate,
    String? description,
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
          'description': _optionalText(description),
          'due_date': _dateOnly(dueDate),
          'is_completed': false,
          'completed_at': null,
          'calendar_event_id': null,
          'reminder_days_before': reminderDaysBefore,
          'notification_id': notificationId,
        })
        .select()
        .single();
    final task = SkillTask.fromJson(row);
    await _cacheTask(task);
    return task;
  }

  Future<SkillTask> updateTask({
    required SkillTask task,
    required String taskTitle,
    required DateTime dueDate,
    String? description,
    int? reminderDaysBefore,
    int? notificationId,
  }) async {
    final row = await _supabase
        .from('skill_tasks')
        .update({
          'task_title': taskTitle.trim(),
          'description': _optionalText(description),
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
    final updated = SkillTask.fromJson(row);
    await _cacheTask(updated);
    return updated;
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
    final updated = SkillTask.fromJson(row);
    await _cacheTask(updated);
    return updated;
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
    final updated = SkillTask.fromJson(row);
    await _cacheTask(updated);
    return updated;
  }

  Future<void> deleteTask(SkillTask task) async {
    await _supabase
        .from('skill_tasks')
        .delete()
        .eq('id', task.id)
        .eq('user_id', _userId)
        .eq('goal_id', task.goalId)
        .eq('skill_id', task.skillId);
    try {
      await _cache.deleteTask(task.userId, task.id);
    } catch (_) {
      // The online deletion remains successful if the cache cannot be updated.
    }
  }

  Future<void> _cacheTasksForSkill(
    String userId,
    String goalId,
    String skillId,
    List<SkillTask> tasks,
  ) async {
    try {
      await _cache.replaceTasksForSkill(
        userId,
        goalId,
        skillId,
        tasks.map((task) => task.toCacheRow()).toList(),
      );
    } catch (_) {
      // Online tasks remain usable if the optional cache cannot be updated.
    }
  }

  Future<void> _cacheTask(SkillTask task) async {
    try {
      await _cache.upsertTask(task.toCacheRow());
    } catch (_) {
      // The online write remains successful if the cache cannot be updated.
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String? _optionalText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
