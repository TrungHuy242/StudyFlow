import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../constants/app_constants.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  Database? _database;
  final DatabaseFactory _dbFactory = createDatabaseFactoryFfiWeb(
    options: SqfliteFfiWebOptions(
      indexedDbName: 'studyflow_databases',
      sqlite3WasmUri: Uri.parse('sqlite3.wasm'),
      sharedWorkerUri: Uri.parse('sqflite_sw.js'),
    ),
  );

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await init();
    return _database!;
  }

  Future<Database> init() async {
    final String dbPath = await _dbFactory.getDatabasesPath();
    final String path = join(dbPath, AppConstants.databaseName);

    _database = await _dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (Database db, int version) async {
          await _createSchema(db);
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          await _upgradeSchema(db, oldVersion);
        },
      ),
    );

    return _database!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE semesters(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE subjects(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semester_id INTEGER,
        name TEXT NOT NULL,
        code TEXT,
        color TEXT,
        credits INTEGER,
        teacher TEXT,
        room TEXT,
        note TEXT,
        FOREIGN KEY (semester_id) REFERENCES semesters(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER,
        weekday INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        room TEXT,
        type TEXT,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE deadlines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT NOT NULL,
        due_time TEXT,
        priority TEXT,
        status TEXT,
        progress INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE study_plans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER,
        title TEXT NOT NULL,
        plan_date TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        duration INTEGER,
        topic TEXT,
        status TEXT,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pomodoro_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER,
        session_date TEXT NOT NULL,
        duration INTEGER NOT NULL,
        type TEXT,
        completed_at TEXT,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER,
        title TEXT NOT NULL,
        content TEXT,
        color TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        title TEXT NOT NULL,
        message TEXT,
        scheduled_at TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        related_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE user_settings(
        id INTEGER PRIMARY KEY,
        display_name TEXT,
        email TEXT,
        avatar TEXT,
        dark_mode INTEGER NOT NULL DEFAULT 0,
        notifications_enabled INTEGER NOT NULL DEFAULT 1,
        onboarding_done INTEGER NOT NULL DEFAULT 0,
        local_password TEXT,
        is_logged_in INTEGER NOT NULL DEFAULT 0,
        focus_duration INTEGER NOT NULL DEFAULT 25,
        short_break_duration INTEGER NOT NULL DEFAULT 5,
        long_break_duration INTEGER NOT NULL DEFAULT 15,
        study_goal_minutes INTEGER NOT NULL DEFAULT 120
      )
    ''');

    await _ensureDefaultSettings(db);
  }

  Future<void> _upgradeSchema(Database db, int oldVersion) async {
    if (oldVersion < 2) {
      await db
          .execute('ALTER TABLE user_settings ADD COLUMN local_password TEXT');
      await db.execute(
        'ALTER TABLE user_settings ADD COLUMN is_logged_in INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE user_settings ADD COLUMN focus_duration INTEGER NOT NULL DEFAULT 25',
      );
      await db.execute(
        'ALTER TABLE user_settings ADD COLUMN short_break_duration INTEGER NOT NULL DEFAULT 5',
      );
      await db.execute(
        'ALTER TABLE user_settings ADD COLUMN long_break_duration INTEGER NOT NULL DEFAULT 15',
      );
      await db.execute(
        'ALTER TABLE user_settings ADD COLUMN study_goal_minutes INTEGER NOT NULL DEFAULT 120',
      );
    }

    await _ensureDefaultSettings(db);
  }

  Future<void> _ensureDefaultSettings(Database db) async {
    final List<Map<String, Object?>> result = await db.query(
      'user_settings',
      limit: 1,
    );

    if (result.isEmpty) {
      await db.insert('user_settings', {
        'id': 1,
        'display_name': 'Student',
        'email': null,
        'avatar': null,
        'dark_mode': 0,
        'notifications_enabled': 1,
        'onboarding_done': 0,
        'local_password': null,
        'is_logged_in': 0,
        'focus_duration': 25,
        'short_break_duration': 5,
        'long_break_duration': 15,
        'study_goal_minutes': 120,
      });
    }
  }
}
