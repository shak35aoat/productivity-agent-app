import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';
import '../models/study_session_model.dart';
import '../models/habit_model.dart';
import '../models/bcs_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('productivity_agent.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        priority TEXT DEFAULT 'medium',
        category TEXT DEFAULT 'other',
        completed INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE study_sessions (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        focus_score INTEGER,
        notes TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        frequency TEXT DEFAULT 'daily',
        streak INTEGER DEFAULT 0,
        last_completed TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await _createBCSTables(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createBCSTables(db);
    }
  }

  Future<void> _createBCSTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bcs_subjects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        total_topics INTEGER NOT NULL,
        completed_topics INTEGER DEFAULT 0,
        category TEXT NOT NULL,
        last_studied TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mock_tests (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        score INTEGER NOT NULL,
        total_marks INTEGER NOT NULL,
        test_name TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<void> init() async {
    await database;
  }

  /// Batch-insert a list of BCS subjects for faster seeding
  Future<void> batchInsertBcsSubjects(List<BcsSubject> subjects) async {
    final db = await database;
    final batch = db.batch();
    for (final subject in subjects) {
      batch.insert('bcs_subjects', subject.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // Task CRUD
  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Task>> getTasks({bool? completed}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    if (completed != null) {
      maps = await db.query('tasks', where: 'completed = ?', whereArgs: [completed ? 1 : 0]);
    } else {
      maps = await db.query('tasks', orderBy: 'created_at DESC');
    }

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTodayTasks() async {
    final db = await database;
    final today = DateTime.now();
    final todayStr = DateTime(today.year, today.month, today.day).toIso8601String();

    final maps = await db.query(
      'tasks',
      where: 'completed = 0 AND (due_date IS NULL OR due_date <= ?)',
      whereArgs: [todayStr],
      orderBy: 'priority DESC, due_date ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Study session CRUD
  Future<void> insertStudySession(StudySession session) async {
    final db = await database;
    await db.insert('study_sessions', session.toMap());
  }

  Future<List<StudySession>> getStudySessions({int? limitDays}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    if (limitDays != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: limitDays));
      maps = await db.query(
        'study_sessions',
        where: 'timestamp >= ?',
        whereArgs: [cutoffDate.toIso8601String()],
        orderBy: 'timestamp DESC',
      );
    } else {
      maps = await db.query('study_sessions', orderBy: 'timestamp DESC');
    }

    return maps.map((map) => StudySession.fromMap(map)).toList();
  }

  Future<int> getTotalStudyMinutes({int? days}) async {
    final sessions = await getStudySessions(limitDays: days);
    return sessions.fold<int>(0, (sum, session) => sum + session.durationMinutes);
  }

  // BCS Subject CRUD
  Future<void> insertBcsSubject(BcsSubject subject) async {
    final db = await database;
    await db.insert('bcs_subjects', subject.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BcsSubject>> getBcsSubjects() async {
    final db = await database;
    final maps = await db.query('bcs_subjects', orderBy: 'category ASC, name ASC');
    return maps.map((m) => BcsSubject.fromMap(m)).toList();
  }

  Future<void> updateBcsSubject(BcsSubject subject) async {
    final db = await database;
    await db.update('bcs_subjects', subject.toMap(), where: 'id = ?', whereArgs: [subject.id]);
  }

  // Mock Test CRUD
  Future<void> insertMockTest(MockTestResult result) async {
    final db = await database;
    await db.insert('mock_tests', result.toMap());
  }

  Future<List<MockTestResult>> getMockTests() async {
    final db = await database;
    final maps = await db.query('mock_tests', orderBy: 'date DESC');
    return maps.map((m) => MockTestResult.fromMap(m)).toList();
  }

  Future<void> deleteMockTest(String id) async {
    final db = await database;
    await db.delete('mock_tests', where: 'id = ?', whereArgs: [id]);
  }

  // Habit CRUD
  Future<void> insertHabit(Habit habit) async {
    final db = await database;
    await db.insert('habits', habit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Habit>> getHabits() async {
    final db = await database;
    final maps = await db.query('habits', orderBy: 'created_at ASC');
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    await db.update('habits', habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<void> deleteHabit(String id) async {
    final db = await database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // Heatmap: returns a map of date string → study minutes for the past N days
  Future<Map<String, int>> getStudyHeatmap({int days = 105}) async {
    final sessions = await getStudySessions(limitDays: days);
    final Map<String, int> heatmap = {};
    for (final session in sessions) {
      final key = '${session.timestamp.year}-${session.timestamp.month.toString().padLeft(2,'0')}-${session.timestamp.day.toString().padLeft(2,'0')}';
      heatmap[key] = (heatmap[key] ?? 0) + session.durationMinutes;
    }
    return heatmap;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
