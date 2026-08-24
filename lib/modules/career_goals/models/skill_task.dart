class SkillTask {
  const SkillTask({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.skillId,
    required this.taskTitle,
    required this.dueDate,
    required this.isCompleted,
    this.completedAt,
    this.calendarEventId,
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
  final DateTime? completedAt;
  final String? calendarEventId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SkillTask.fromJson(Map<String, dynamic> json) => SkillTask(
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    goalId: json['goal_id'].toString(),
    skillId: json['skill_id'].toString(),
    taskTitle: json['task_title'].toString(),
    dueDate: DateTime.parse(json['due_date'].toString()),
    isCompleted: json['is_completed'] as bool? ?? false,
    completedAt: _dateTimeOrNull(json['completed_at']),
    calendarEventId: json['calendar_event_id'] as String?,
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
    'completed_at': completedAt?.toUtc().toIso8601String(),
    'calendar_event_id': calendarEventId,
    'created_at': createdAt?.toUtc().toIso8601String(),
    'updated_at': updatedAt?.toUtc().toIso8601String(),
  };

  static DateTime? _dateTimeOrNull(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
