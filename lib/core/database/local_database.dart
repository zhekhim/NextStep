import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'database_tables.dart';

abstract class LocalCache {
  Future<List<Map<String, Object?>>> readCareerFairs();
  Future<void> replaceCareerFairs(List<Map<String, Object?>> rows);
  Future<List<Map<String, Object?>>> readAssessmentQuestions();
  Future<void> replaceAssessmentQuestions(List<Map<String, Object?>> rows);
  Future<List<Map<String, Object?>>> readMilestoneTemplates(String skillId);
  Future<void> replaceMilestoneTemplates(
    String skillId,
    List<Map<String, Object?>> rows,
  );
  Future<List<Map<String, Object?>>> readCareerRequirements(String careerId);
  Future<void> replaceCareerRequirements(
    String careerId,
    List<Map<String, Object?>> rows,
  );
  Future<List<Map<String, Object?>>> readTasksForSkill(
    String userId,
    String goalId,
    String skillId,
  );
  Future<List<Map<String, Object?>>> readTasksForGoal(
    String userId,
    String goalId,
  );
  Future<void> replaceTasksForSkill(
    String userId,
    String goalId,
    String skillId,
    List<Map<String, Object?>> rows,
  );
  Future<void> replaceTasksForGoal(
    String userId,
    String goalId,
    List<Map<String, Object?>> rows,
  );
  Future<void> upsertTask(Map<String, Object?> row);
  Future<void> deleteTask(String userId, String taskId);
  Future<Map<String, Object?>?> readProfile(String userId);
  Future<void> upsertProfile(Map<String, Object?> row);
}

class LocalDatabase implements LocalCache {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();
  static const databaseName = 'nextstep.db';
  static const databaseVersion = 2;

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final databasePath = path.join(await getDatabasesPath(), databaseName);
    return _database = await openDatabase(
      databasePath,
      version: databaseVersion,
      onCreate: (database, version) async {
        for (final statement in DatabaseTables.createStatements) {
          await database.execute(statement);
        }
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          for (final statement in DatabaseTables.version2Statements) {
            await database.execute(statement);
          }
        }
      },
    );
  }

  @override
  Future<List<Map<String, Object?>>> readCareerFairs() async =>
      (await database).query(
        DatabaseTables.careerFairsCache,
        orderBy: 'event_date ASC, start_time ASC, title ASC',
      );

  @override
  Future<void> replaceCareerFairs(List<Map<String, Object?>> rows) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete(DatabaseTables.careerFairsCache);
      final batch = transaction.batch();
      for (final row in rows) {
        batch.insert(DatabaseTables.careerFairsCache, row);
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<List<Map<String, Object?>>> readAssessmentQuestions() async =>
      (await database).query(
        DatabaseTables.assessmentQuestionsCache,
        orderBy: 'question_order ASC',
      );

  @override
  Future<void> replaceAssessmentQuestions(
    List<Map<String, Object?>> rows,
  ) async {
    await _replaceAll(DatabaseTables.assessmentQuestionsCache, rows);
  }

  @override
  Future<List<Map<String, Object?>>> readMilestoneTemplates(
    String skillId,
  ) async => (await database).query(
    DatabaseTables.skillMilestoneTemplatesCache,
    where: 'skill_id = ?',
    whereArgs: [skillId],
    orderBy: 'milestone_order ASC',
  );

  @override
  Future<void> replaceMilestoneTemplates(
    String skillId,
    List<Map<String, Object?>> rows,
  ) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete(
        DatabaseTables.skillMilestoneTemplatesCache,
        where: 'skill_id = ?',
        whereArgs: [skillId],
      );
      final batch = transaction.batch();
      for (final row in rows) {
        batch.insert(DatabaseTables.skillMilestoneTemplatesCache, row);
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<List<Map<String, Object?>>> readCareerRequirements(
    String careerId,
  ) async => (await database).query(
    DatabaseTables.careerRequirementsCache,
    where: 'career_id = ?',
    whereArgs: [careerId],
    orderBy: 'skill_name ASC',
  );

  @override
  Future<void> replaceCareerRequirements(
    String careerId,
    List<Map<String, Object?>> rows,
  ) async {
    await _replaceScope(
      table: DatabaseTables.careerRequirementsCache,
      where: 'career_id = ?',
      whereArgs: [careerId],
      rows: rows,
    );
  }

  @override
  Future<List<Map<String, Object?>>> readTasksForSkill(
    String userId,
    String goalId,
    String skillId,
  ) async => (await database).query(
    DatabaseTables.skillTasksCache,
    where: 'user_id = ? AND goal_id = ? AND skill_id = ?',
    whereArgs: [userId, goalId, skillId],
    orderBy: 'is_completed ASC, due_date ASC, created_at ASC',
  );

  @override
  Future<List<Map<String, Object?>>> readTasksForGoal(
    String userId,
    String goalId,
  ) async => (await database).query(
    DatabaseTables.skillTasksCache,
    where: 'user_id = ? AND goal_id = ?',
    whereArgs: [userId, goalId],
    orderBy: 'is_completed ASC, due_date ASC, created_at ASC',
  );

  @override
  Future<void> replaceTasksForSkill(
    String userId,
    String goalId,
    String skillId,
    List<Map<String, Object?>> rows,
  ) async {
    await _replaceScope(
      table: DatabaseTables.skillTasksCache,
      where: 'user_id = ? AND goal_id = ? AND skill_id = ?',
      whereArgs: [userId, goalId, skillId],
      rows: rows,
    );
  }

  @override
  Future<void> replaceTasksForGoal(
    String userId,
    String goalId,
    List<Map<String, Object?>> rows,
  ) async {
    await _replaceScope(
      table: DatabaseTables.skillTasksCache,
      where: 'user_id = ? AND goal_id = ?',
      whereArgs: [userId, goalId],
      rows: rows,
    );
  }

  @override
  Future<void> upsertTask(Map<String, Object?> row) async {
    await (await database).insert(
      DatabaseTables.skillTasksCache,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    await (await database).delete(
      DatabaseTables.skillTasksCache,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, taskId],
    );
  }

  @override
  Future<Map<String, Object?>?> readProfile(String userId) async {
    final rows = await (await database).query(
      DatabaseTables.profileCache,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<void> upsertProfile(Map<String, Object?> row) async {
    await (await database).insert(
      DatabaseTables.profileCache,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _replaceAll(
    String table,
    List<Map<String, Object?>> rows,
  ) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete(table);
      final batch = transaction.batch();
      for (final row in rows) {
        batch.insert(table, row);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> _replaceScope({
    required String table,
    required String where,
    required List<Object?> whereArgs,
    required List<Map<String, Object?>> rows,
  }) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete(table, where: where, whereArgs: whereArgs);
      final batch = transaction.batch();
      for (final row in rows) {
        batch.insert(table, row);
      }
      await batch.commit(noResult: true);
    });
  }
}
