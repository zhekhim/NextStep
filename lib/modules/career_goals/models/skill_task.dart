class SkillTask {
  const SkillTask({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.skillId,
    required this.taskTitle,
    required this.dueDate,
    required this.isCompleted,
    this.templateId,
    this.description,
    this.completionEvidence,
    this.completedAt,
    this.calendarEventId,
    this.reminderDaysBefore,
    this.notificationId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String goalId;
  final String skillId;
  final String taskTitle;
  final DateTime dueDate;
  final bool isCompleted;
  final String? templateId;
  final String? description;
  final String? completionEvidence;
  final DateTime? completedAt;
  final String? calendarEventId;
  final int? reminderDaysBefore;
  final int? notificationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SkillTask.fromJson(Map<String, dynamic> json) => SkillTask(
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    goalId: json['goal_id'].toString(),
    skillId: json['skill_id'].toString(),
    taskTitle: json['task_title'].toString(),
    dueDate: DateTime.parse(json['due_date'].toString()),
    isCompleted: _boolValue(json['is_completed']),
    templateId: json['template_id'] as String?,
    description: json['description'] as String?,
    completionEvidence: json['completion_evidence'] as String?,
    completedAt: _dateTimeOrNull(json['completed_at']),
    calendarEventId: json['calendar_event_id'] as String?,
    reminderDaysBefore: json['reminder_days_before'] as int?,
    notificationId: json['notification_id'] as int?,
    createdAt: _dateTimeOrNull(json['created_at']),
    updatedAt: _dateTimeOrNull(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'goal_id': goalId,
    'skill_id': skillId,
    'task_title': taskTitle,
    'due_date': _dateOnly(dueDate),
    'is_completed': isCompleted,
    'template_id': templateId,
    'description': description,
    'completion_evidence': completionEvidence,
    'completed_at': completedAt?.toUtc().toIso8601String(),
    'calendar_event_id': calendarEventId,
    'reminder_days_before': reminderDaysBefore,
    'notification_id': notificationId,
    'created_at': createdAt?.toUtc().toIso8601String(),
    'updated_at': updatedAt?.toUtc().toIso8601String(),
  };

  Map<String, Object?> toCacheRow() => {
    ...toJson(),
    'is_completed': isCompleted ? 1 : 0,
  };

  static DateTime? _dateTimeOrNull(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static bool _boolValue(Object? value) =>
      value == true || value == 1 || value?.toString().toLowerCase() == 'true';

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class SkillMilestoneTemplate {
  const SkillMilestoneTemplate({
    required this.id,
    required this.skillId,
    required this.order,
    required this.targetLevel,
    required this.title,
    required this.description,
    required this.completionEvidence,
    required this.suggestedDurationDays,
    this.updatedAt,
  });

  final String id;
  final String skillId;
  final int order;
  final String targetLevel;
  final String title;
  final String description;
  final String completionEvidence;
  final int suggestedDurationDays;
  final DateTime? updatedAt;

  factory SkillMilestoneTemplate.fromJson(Map<String, dynamic> json) =>
      SkillMilestoneTemplate(
        id: json['id'].toString(),
        skillId: json['skill_id'].toString(),
        order: json['milestone_order'] as int,
        targetLevel: json['target_level'].toString(),
        title: json['title'].toString(),
        description: json['description'].toString(),
        completionEvidence: json['completion_evidence'].toString(),
        suggestedDurationDays: json['suggested_duration_days'] as int,
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      );

  Map<String, Object?> toCacheRow() => {
    'id': id,
    'skill_id': skillId,
    'milestone_order': order,
    'target_level': targetLevel,
    'title': title,
    'description': description,
    'completion_evidence': completionEvidence,
    'suggested_duration_days': suggestedDurationDays,
    'updated_at': updatedAt?.toUtc().toIso8601String(),
  };
}
