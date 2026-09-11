import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/core/database/local_database.dart';
import 'package:untitled/modules/career_assessment/repositories/assessment_question_repository.dart';
import 'package:untitled/modules/career_goals/repositories/career_goal_repository.dart';
import 'package:untitled/modules/career_goals/repositories/skill_task_repository.dart';
import 'package:untitled/modules/career_intelligence/repositories/career_fair_repository.dart';
import 'package:untitled/modules/profile_skills/models/profile.dart';
import 'package:untitled/modules/profile_skills/repositories/profile_repository.dart';

void main() {
  late _MemoryCache cache;
  late SupabaseClient offlineClient;

  setUp(() {
    cache = _MemoryCache();
    offlineClient = SupabaseClient(
      'https://offline.invalid',
      'sb_publishable_test',
      httpClient: MockClient(
        (_) async => Response(jsonEncode({'message': 'offline'}), 503),
      ),
    );
  });

  test('career fairs remain available when the online fetch fails', () async {
    cache.careerFairs = [_careerFairRow];
    final repository = SupabaseCareerFairRepository(
      client: offlineClient,
      cache: cache,
    );

    final fairs = await repository.getUpcomingCareerFairs(
      now: DateTime(2026, 9, 11),
    );

    expect(fairs.single.title, 'Cached Career Fair');
    expect(fairs.single.latitude, 3.139);
  });

  test('online career fairs replace the local cache', () async {
    final repository = SupabaseCareerFairRepository(
      client: _clientReturning([_careerFairRow]),
      cache: cache,
    );

    final fairs = await repository.getUpcomingCareerFairs(
      now: DateTime(2026, 9, 11),
    );

    expect(fairs.single.id, 'fair-1');
    expect(cache.careerFairs.single['title'], 'Cached Career Fair');
  });

  test('assessment questions fall back to SQLite when offline', () async {
    cache.questions = [
      {
        'id': 'question-1',
        'question_text': 'Build practical things',
        'dimension': 'R',
        'question_order': 1,
        'updated_at': '2026-09-11T00:00:00Z',
      },
    ];
    final repository = AssessmentQuestionRepository(
      client: offlineClient,
      cache: cache,
    );

    final questions = await repository.getActiveQuestions();

    expect(questions.single.activity, 'Build practical things');
    expect(questions.single.order, 1);
  });

  test('online assessment questions replace the local cache', () async {
    final repository = AssessmentQuestionRepository(
      client: _clientReturning([
        {
          'id': 'question-online',
          'question_text': 'Research a difficult problem',
          'dimension': 'I',
          'question_order': 2,
          'updated_at': '2026-09-11T00:00:00Z',
        },
      ]),
      cache: cache,
    );

    await repository.refreshQuestions();

    expect(cache.questions.single['id'], 'question-online');
  });

  test('milestone cache keeps cumulative level filtering offline', () async {
    cache.templates['skill-1'] = [
      _templateRow('beginner', 1, 'Beginner'),
      _templateRow('intermediate', 2, 'Intermediate'),
      _templateRow('advanced', 3, 'Advanced'),
    ];
    final repository = SkillTaskRepository(client: offlineClient, cache: cache);

    final templates = await repository.getRecommendedTemplates(
      skillId: 'skill-1',
      currentLevel: 'Beginner',
      requiredLevel: 'Advanced',
    );

    expect(templates.map((template) => template.targetLevel), [
      'Intermediate',
      'Advanced',
    ]);
  });

  test('online milestone templates replace that skill cache', () async {
    final repository = SkillTaskRepository(
      client: _clientReturning([
        _templateRow('intermediate', 2, 'Intermediate'),
      ]),
      cache: cache,
    );

    await repository.getRecommendedTemplates(
      skillId: 'skill-1',
      currentLevel: 'Beginner',
      requiredLevel: 'Advanced',
    );

    expect(cache.templates['skill-1']?.single['id'], 'intermediate');
  });

  test('career requirements remain browsable offline by career', () async {
    cache.requirements['career-1'] = [
      {
        'career_id': 'career-1',
        'skill_id': 'skill-a',
        'skill_name': 'Programming',
        'required_level': 'Advanced',
        'updated_at': '2026-09-11T00:00:00Z',
      },
      {
        'career_id': 'career-1',
        'skill_id': 'skill-b',
        'skill_name': 'Software Development',
        'required_level': 'Intermediate',
        'updated_at': '2026-09-11T00:00:00Z',
      },
    ];
    final repository = CareerGoalRepository(
      client: offlineClient,
      cache: cache,
    );

    final requirements = await repository.getRequirements('career-1');

    expect(requirements.map((item) => item.skillId), ['skill-a', 'skill-b']);
  });

  test('online career requirements replace only that career cache', () async {
    cache.requirements['career-other'] = [
      {
        'career_id': 'career-other',
        'skill_id': 'other-skill',
        'skill_name': 'Other Skill',
        'required_level': 'Beginner',
        'updated_at': '2026-09-11T00:00:00Z',
      },
    ];
    final client = SupabaseClient(
      'https://online.example.com',
      'sb_publishable_test',
      httpClient: MockClient((request) async {
        final rows = request.url.path.endsWith('/career_skills')
            ? [
                {'skill_id': 'skill-a', 'required_level': 'Advanced'},
              ]
            : [
                {'id': 'skill-a', 'skill_name': 'Programming'},
              ];
        return Response(
          jsonEncode(rows),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    final repository = CareerGoalRepository(client: client, cache: cache);

    await repository.getRequirements('career-1');

    expect(cache.requirements['career-1']?.single['skill_id'], 'skill-a');
    expect(
      cache.requirements['career-other']?.single['skill_id'],
      'other-skill',
    );
  });

  test('same-title cached tasks remain independent between skills', () async {
    cache.tasks.addAll([
      _taskRow('task-a', 'skill-a', completed: true),
      _taskRow('task-b', 'skill-b', completed: false),
    ]);
    final repository = SkillTaskRepository(
      client: offlineClient,
      cache: cache,
      userId: 'user-1',
    );

    final skillA = await repository.getTasksForSkill(
      goalId: 'goal-1',
      skillId: 'skill-a',
    );
    final skillB = await repository.getTasksForSkill(
      goalId: 'goal-1',
      skillId: 'skill-b',
    );

    expect(skillA.single.taskTitle, skillB.single.taskTitle);
    expect(skillA.single.isCompleted, isTrue);
    expect(skillB.single.isCompleted, isFalse);
  });

  test(
    'online task fetch replaces only its user goal and skill scope',
    () async {
      cache.tasks.add(_taskRow('old-b', 'skill-b', completed: false));
      final repository = SkillTaskRepository(
        client: _clientReturning([
          _taskRow('fresh-a', 'skill-a', completed: false),
        ]),
        cache: cache,
        userId: 'user-1',
      );

      await repository.getTasksForSkill(goalId: 'goal-1', skillId: 'skill-a');

      expect(cache.tasks.any((row) => row['id'] == 'fresh-a'), isTrue);
      expect(cache.tasks.any((row) => row['id'] == 'old-b'), isTrue);
    },
  );

  test('profile cache round-trips user data without image bytes', () async {
    final repository = ProfileRepository(client: offlineClient, cache: cache);
    const profile = Profile(
      userId: 'user-1',
      fullName: 'Cached Student',
      email: 'student@example.com',
      university: 'Example University',
      major: 'Computing',
      yearOfStudy: '2',
      avatarUrl: 'https://example.com/avatar.jpg',
      targetedJobRoles: ['Software Developer'],
    );

    await repository.cacheProfile(profile);
    final cached = await repository.getCachedProfile(userId: 'user-1');

    expect(cached?.fullName, profile.fullName);
    expect(cached?.targetedJobRoles, profile.targetedJobRoles);
    expect(cache.profile?.containsKey('image_bytes'), isFalse);
    expect(cache.profile?['avatar_url'], profile.avatarUrl);
  });
}

SupabaseClient _clientReturning(List<Map<String, Object?>> rows) =>
    SupabaseClient(
      'https://online.example.com',
      'sb_publishable_test',
      httpClient: MockClient(
        (request) async => Response(
          jsonEncode(rows),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
    );

final _careerFairRow = <String, Object?>{
  'id': 'fair-1',
  'title': 'Cached Career Fair',
  'organiser': 'Example Organiser',
  'description': 'Cached event',
  'event_date': '2026-10-20',
  'start_time': '09:00:00',
  'end_time': '17:00:00',
  'venue': 'Convention Centre',
  'address': 'Kuala Lumpur',
  'latitude': 3.139,
  'longitude': 101.6869,
  'registration_url': null,
  'source_url': 'https://example.com',
  'created_at': '2026-09-01T00:00:00Z',
  'updated_at': '2026-09-11T00:00:00Z',
};

Map<String, Object?> _templateRow(String id, int order, String level) => {
  'id': id,
  'skill_id': 'skill-1',
  'milestone_order': order,
  'target_level': level,
  'title': '$level milestone',
  'description': 'Learn the skill',
  'completion_evidence': 'Completed work',
  'suggested_duration_days': 7,
  'updated_at': '2026-09-11T00:00:00Z',
};

Map<String, Object?> _taskRow(
  String id,
  String skillId, {
  required bool completed,
}) => {
  'id': id,
  'user_id': 'user-1',
  'goal_id': 'goal-1',
  'skill_id': skillId,
  'template_id': null,
  'task_title': 'Complete a guided Programming exercise',
  'description': null,
  'completion_evidence': null,
  'due_date': '2026-10-20',
  'is_completed': completed ? 1 : 0,
  'completed_at': completed ? '2026-09-11T00:00:00Z' : null,
  'calendar_event_id': null,
  'reminder_days_before': null,
  'notification_id': null,
  'created_at': '2026-09-01T00:00:00Z',
  'updated_at': '2026-09-11T00:00:00Z',
};

class _MemoryCache implements LocalCache {
  List<Map<String, Object?>> careerFairs = [];
  List<Map<String, Object?>> questions = [];
  final templates = <String, List<Map<String, Object?>>>{};
  final requirements = <String, List<Map<String, Object?>>>{};
  final tasks = <Map<String, Object?>>[];
  Map<String, Object?>? profile;

  @override
  Future<List<Map<String, Object?>>> readAssessmentQuestions() async =>
      questions;

  @override
  Future<List<Map<String, Object?>>> readCareerFairs() async => careerFairs;

  @override
  Future<List<Map<String, Object?>>> readCareerRequirements(
    String careerId,
  ) async => requirements[careerId] ?? [];

  @override
  Future<List<Map<String, Object?>>> readMilestoneTemplates(
    String skillId,
  ) async => templates[skillId] ?? [];

  @override
  Future<Map<String, Object?>?> readProfile(String userId) async =>
      profile?['user_id'] == userId ? profile : null;

  @override
  Future<List<Map<String, Object?>>> readTasksForGoal(
    String userId,
    String goalId,
  ) async => tasks
      .where((row) => row['user_id'] == userId && row['goal_id'] == goalId)
      .toList();

  @override
  Future<List<Map<String, Object?>>> readTasksForSkill(
    String userId,
    String goalId,
    String skillId,
  ) async => tasks
      .where(
        (row) =>
            row['user_id'] == userId &&
            row['goal_id'] == goalId &&
            row['skill_id'] == skillId,
      )
      .toList();

  @override
  Future<void> replaceAssessmentQuestions(
    List<Map<String, Object?>> rows,
  ) async => questions = rows;

  @override
  Future<void> replaceCareerFairs(List<Map<String, Object?>> rows) async =>
      careerFairs = rows;

  @override
  Future<void> replaceCareerRequirements(
    String careerId,
    List<Map<String, Object?>> rows,
  ) async => requirements[careerId] = rows;

  @override
  Future<void> replaceMilestoneTemplates(
    String skillId,
    List<Map<String, Object?>> rows,
  ) async => templates[skillId] = rows;

  @override
  Future<void> replaceTasksForGoal(
    String userId,
    String goalId,
    List<Map<String, Object?>> rows,
  ) async {
    tasks.removeWhere(
      (row) => row['user_id'] == userId && row['goal_id'] == goalId,
    );
    tasks.addAll(rows);
  }

  @override
  Future<void> replaceTasksForSkill(
    String userId,
    String goalId,
    String skillId,
    List<Map<String, Object?>> rows,
  ) async {
    tasks.removeWhere(
      (row) =>
          row['user_id'] == userId &&
          row['goal_id'] == goalId &&
          row['skill_id'] == skillId,
    );
    tasks.addAll(rows);
  }

  @override
  Future<void> upsertTask(Map<String, Object?> row) async {
    tasks.removeWhere((item) => item['id'] == row['id']);
    tasks.add(row);
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    tasks.removeWhere((row) => row['user_id'] == userId && row['id'] == taskId);
  }

  @override
  Future<void> upsertProfile(Map<String, Object?> row) async => profile = row;
}
