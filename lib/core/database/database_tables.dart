class DatabaseTables {
  DatabaseTables._();

  static const careerFairsCache = 'career_fairs_cache';
  static const assessmentQuestionsCache = 'assessment_questions_cache';
  static const skillMilestoneTemplatesCache = 'skill_milestone_templates_cache';
  static const careerRequirementsCache = 'career_requirements_cache';
  static const skillTasksCache = 'skill_tasks_cache';
  static const profileCache = 'profile_cache';

  static const createCareerRequirementsCache =
      '''
    CREATE TABLE $careerRequirementsCache (
      career_id TEXT NOT NULL,
      skill_id TEXT NOT NULL,
      skill_name TEXT NOT NULL,
      required_level TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      PRIMARY KEY (career_id, skill_id)
    )
  ''';

  static const createSkillTasksCache =
      '''
    CREATE TABLE $skillTasksCache (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      goal_id TEXT NOT NULL,
      skill_id TEXT NOT NULL,
      template_id TEXT,
      task_title TEXT NOT NULL,
      description TEXT,
      completion_evidence TEXT,
      due_date TEXT NOT NULL,
      is_completed INTEGER NOT NULL,
      completed_at TEXT,
      calendar_event_id TEXT,
      reminder_days_before INTEGER,
      notification_id INTEGER,
      created_at TEXT,
      updated_at TEXT
    )
  ''';

  static const createStatements = [
    '''
      CREATE TABLE $careerFairsCache (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        organiser TEXT NOT NULL,
        description TEXT NOT NULL,
        event_date TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        venue TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        registration_url TEXT,
        source_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE $assessmentQuestionsCache (
        id TEXT PRIMARY KEY,
        question_text TEXT NOT NULL,
        dimension TEXT NOT NULL,
        question_order INTEGER NOT NULL,
        updated_at TEXT
      )
    ''',
    '''
      CREATE TABLE $skillMilestoneTemplatesCache (
        id TEXT PRIMARY KEY,
        skill_id TEXT NOT NULL,
        milestone_order INTEGER NOT NULL,
        target_level TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        completion_evidence TEXT NOT NULL,
        suggested_duration_days INTEGER NOT NULL,
        updated_at TEXT
      )
    ''',
    createCareerRequirementsCache,
    createSkillTasksCache,
    '''
      CREATE TABLE $profileCache (
        user_id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL,
        university TEXT,
        major TEXT,
        year_of_study TEXT,
        preferred_employment_state TEXT,
        targeted_roles TEXT NOT NULL,
        avatar_url TEXT,
        title TEXT,
        bio TEXT,
        updated_at TEXT NOT NULL
      )
    ''',
  ];

  static const version2Statements = [
    createCareerRequirementsCache,
    createSkillTasksCache,
  ];
}
