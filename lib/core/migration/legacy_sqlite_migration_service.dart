import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../features/profile/data/user_settings_model.dart';
import '../auth/supabase_auth_storage.dart';
import '../data/user_scope.dart';
import '../database/database_service.dart';
import '../database/legacy_database_service.dart';
import '../utils/database_value_utils.dart';
import '../utils/date_time_utils.dart';

class LegacySqliteMigrationService {
  LegacySqliteMigrationService(this._databaseService);

  final DatabaseService _databaseService;

  Future<LegacyMigrationSummary> migrateForCurrentUser(
    UserSettingsModel profile,
  ) async {
    final String? userId = profile.userId;
    if (!profile.isAuthenticated || userId == null) {
      return const LegacyMigrationSummary(
        imported: false,
        reason: 'No authenticated user is available for legacy import.',
      );
    }

    final DateTime? alreadyMigrated =
        await SupabaseAuthStorage.instance.readLegacyMigratedAt(userId);
    if (alreadyMigrated != null) {
      return const LegacyMigrationSummary(
        imported: false,
        reason: 'Legacy migration already completed for this user on this device.',
      );
    }

    final Database legacyDatabase = await LegacyDatabaseService.instance.database;
    final _LegacySnapshot snapshot = await _readLegacySnapshot(legacyDatabase);

    if (!_hasMeaningfulLegacyData(snapshot)) {
      await SupabaseAuthStorage.instance.writeLegacyMigratedAt(
        userId,
        DateTime.now(),
      );
      return const LegacyMigrationSummary(
        imported: false,
        reason: 'No meaningful legacy SQLite data was found.',
      );
    }

    if (await _remoteHasMeaningfulData(userId)) {
      await SupabaseAuthStorage.instance.writeLegacyMigratedAt(
        userId,
        DateTime.now(),
      );
      return const LegacyMigrationSummary(
        imported: false,
        reason: 'Current user already has remote data.',
      );
    }

    await _importSnapshot(snapshot, userId);
    await _mergeLegacySettings(profile, snapshot.userSettings);
    await SupabaseAuthStorage.instance.writeLegacyMigratedAt(
      userId,
      DateTime.now(),
    );

    return LegacyMigrationSummary(
      imported: true,
      reason: 'Legacy SQLite data imported into Supabase for the current user.',
      importedCounts: <String, int>{
        'semesters': snapshot.semesters.length,
        'subjects': snapshot.subjects.length,
        'schedules': snapshot.schedules.length,
        'deadlines': snapshot.deadlines.length,
        'study_plans': snapshot.studyPlans.length,
        'pomodoro_sessions': snapshot.pomodoroSessions.length,
        'notes': snapshot.notes.length,
        'notifications': snapshot.notifications.length,
      },
    );
  }

  Future<_LegacySnapshot> _readLegacySnapshot(Database legacyDatabase) async {
    return _LegacySnapshot(
      semesters: await legacyDatabase.query('semesters'),
      subjects: await legacyDatabase.query('subjects'),
      schedules: await legacyDatabase.query('schedules'),
      deadlines: await legacyDatabase.query('deadlines'),
      studyPlans: await legacyDatabase.query('study_plans'),
      pomodoroSessions: await legacyDatabase.query('pomodoro_sessions'),
      notes: await legacyDatabase.query('notes'),
      notifications: await legacyDatabase.query('notifications'),
      userSettings: (await legacyDatabase.query('user_settings', limit: 1))
          .cast<Map<String, Object?>>()
          .firstOrNull,
    );
  }

  bool _hasMeaningfulLegacyData(_LegacySnapshot snapshot) {
    if (snapshot.semesters.isNotEmpty ||
        snapshot.subjects.isNotEmpty ||
        snapshot.schedules.isNotEmpty ||
        snapshot.deadlines.isNotEmpty ||
        snapshot.studyPlans.isNotEmpty ||
        snapshot.pomodoroSessions.isNotEmpty ||
        snapshot.notes.isNotEmpty ||
        snapshot.notifications.isNotEmpty) {
      return true;
    }

    final Map<String, Object?>? settings = snapshot.userSettings;
    if (settings == null) {
      return false;
    }

    return (settings['display_name'] as String? ?? '').trim() != 'Student' ||
        DatabaseValueUtils.asBool(settings['dark_mode']) ||
        !DatabaseValueUtils.asBool(
          settings['notifications_enabled'],
          fallback: true,
        ) ||
        DatabaseValueUtils.asBool(settings['onboarding_done']) ||
        DatabaseValueUtils.asInt(settings['focus_duration'], fallback: 25) !=
            25 ||
        DatabaseValueUtils.asInt(settings['short_break_duration'], fallback: 5) !=
            5 ||
        DatabaseValueUtils.asInt(settings['long_break_duration'], fallback: 15) !=
            15 ||
        DatabaseValueUtils.asInt(settings['study_goal_minutes'], fallback: 120) !=
            120;
  }

  Future<bool> _remoteHasMeaningfulData(String userId) async {
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    const List<String> tables = <String>[
      'semesters',
      'subjects',
      'schedules',
      'deadlines',
      'study_plans',
      'pomodoro_sessions',
      'notes',
      'notifications',
    ];

    for (final String table in tables) {
      final List<dynamic> result = await _databaseService.client
          .from(table)
          .select('id')
          .gte('id', minId)
          .lt('id', maxId)
          .limit(1);
      if (result.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<void> _importSnapshot(_LegacySnapshot snapshot, String userId) async {
    if (snapshot.semesters.isNotEmpty) {
      await _databaseService.client.from('semesters').upsert(
            snapshot.semesters
                .map((Map<String, Object?> row) => _semesterPayload(row, userId))
                .toList(),
            onConflict: 'id',
          );
    }
    if (snapshot.subjects.isNotEmpty) {
      await _databaseService.client.from('subjects').upsert(
            snapshot.subjects
                .map((Map<String, Object?> row) => _subjectPayload(row, userId))
                .toList(),
            onConflict: 'id',
          );
    }
    if (snapshot.schedules.isNotEmpty) {
      await _databaseService.client.from('schedules').upsert(
            snapshot.schedules
                .map((Map<String, Object?> row) => _schedulePayload(row, userId))
                .toList(),
            onConflict: 'id',
          );
    }
    if (snapshot.deadlines.isNotEmpty) {
      await _databaseService.client.from('deadlines').upsert(
            snapshot.deadlines
                .map((Map<String, Object?> row) => _deadlinePayload(row, userId))
                .toList(),
            onConflict: 'id',
          );
    }
    if (snapshot.studyPlans.isNotEmpty) {
      await _databaseService.client.from('study_plans').upsert(
            snapshot.studyPlans
                .map((Map<String, Object?> row) => _studyPlanPayload(row, userId))
                .toList(),
            onConflict: 'id',
          );
    }
    if (snapshot.pomodoroSessions.isNotEmpty) {
      await _databaseService.client.from('pomodoro_sessions').upsert(
            snapshot.pomodoroSessions
                .map((Map<String, Object?> row) => _pomodoroPayload(row, userId))
                .toList(),
            onConflict: 'id',
          );
    }
    if (snapshot.notes.isNotEmpty) {
      await _databaseService.client.from('notes').upsert(
            snapshot.notes
                .map((Map<String, Object?> row) => _notePayload(row, userId))
                .toList(),
            onConflict: 'id',
          );
    }
    if (snapshot.notifications.isNotEmpty) {
      await _databaseService.client.from('notifications').upsert(
            snapshot.notifications
                .map(
                  (Map<String, Object?> row) =>
                      _notificationPayload(row, userId),
                )
                .toList(),
            onConflict: 'id',
          );
    }

    try {
      await _databaseService.client.rpc('reset_studyflow_sequences');
    } catch (error) {
      debugPrint('Sequence reset skipped: $error');
    }
  }

  Future<void> _mergeLegacySettings(
    UserSettingsModel profile,
    Map<String, Object?>? legacySettings,
  ) async {
    if (profile.userId == null || legacySettings == null) {
      return;
    }

    await _databaseService.client.from('user_settings').upsert(
      <String, Object?>{
        'id': UserScope.profileRowId(profile.userId!),
        'display_name':
            (legacySettings['display_name'] as String? ?? '').trim().isNotEmpty &&
                    profile.displayName == 'Student'
                ? (legacySettings['display_name'] as String? ?? '').trim()
                : profile.displayName,
        'email': profile.email,
        'avatar': profile.avatar,
        'dark_mode': DatabaseValueUtils.asBool(legacySettings['dark_mode']) ||
                profile.darkMode
            ? true
            : profile.darkMode,
        'notifications_enabled': DatabaseValueUtils.asBool(
          legacySettings['notifications_enabled'],
          fallback: profile.notificationsEnabled,
        ),
        'onboarding_done': DatabaseValueUtils.asBool(
              legacySettings['onboarding_done'],
            ) ||
            profile.onboardingDone,
        'local_password': null,
        'is_logged_in': false,
        'focus_duration': _preferLegacyInt(
          current: profile.focusDuration,
          currentDefault: 25,
          legacy: legacySettings['focus_duration'],
          legacyDefault: 25,
        ),
        'short_break_duration': _preferLegacyInt(
          current: profile.shortBreakDuration,
          currentDefault: 5,
          legacy: legacySettings['short_break_duration'],
          legacyDefault: 5,
        ),
        'long_break_duration': _preferLegacyInt(
          current: profile.longBreakDuration,
          currentDefault: 15,
          legacy: legacySettings['long_break_duration'],
          legacyDefault: 15,
        ),
        'study_goal_minutes': _preferLegacyInt(
          current: profile.studyGoalMinutes,
          currentDefault: 120,
          legacy: legacySettings['study_goal_minutes'],
          legacyDefault: 120,
        ),
      },
      onConflict: 'id',
    );
  }

  int _preferLegacyInt({
    required int current,
    required int currentDefault,
    required Object? legacy,
    required int legacyDefault,
  }) {
    final int legacyValue =
        DatabaseValueUtils.asInt(legacy, fallback: legacyDefault);
    if (current != currentDefault) {
      return current;
    }
    return legacyValue;
  }

  Map<String, Object?> _semesterPayload(Map<String, Object?> row, String userId) {
    return <String, Object?>{
      'id': UserScope.mapLegacyId(userId, DatabaseValueUtils.asInt(row['id'])),
      'name': row['name'] as String? ?? '',
      'start_date': row['start_date'] as String? ?? '',
      'end_date': row['end_date'] as String? ?? '',
      'is_active': DatabaseValueUtils.asBool(row['is_active']),
    };
  }

  Map<String, Object?> _subjectPayload(Map<String, Object?> row, String userId) {
    return <String, Object?>{
      'id': UserScope.mapLegacyId(userId, DatabaseValueUtils.asInt(row['id'])),
      'semester_id': row['semester_id'] == null
          ? null
          : UserScope.mapLegacyId(
              userId,
              DatabaseValueUtils.asInt(row['semester_id']),
            ),
      'name': row['name'] as String? ?? '',
      'code': row['code'] as String? ?? '',
      'color': row['color'] as String? ?? '#2563EB',
      'credits': DatabaseValueUtils.asInt(row['credits'], fallback: 3),
      'teacher': row['teacher'] as String? ?? '',
      'room': row['room'] as String? ?? '',
      'note': row['note'] as String? ?? '',
    };
  }

  Map<String, Object?> _schedulePayload(
    Map<String, Object?> row,
    String userId,
  ) {
    return <String, Object?>{
      'id': UserScope.mapLegacyId(userId, DatabaseValueUtils.asInt(row['id'])),
      'subject_id': UserScope.mapLegacyId(
        userId,
        DatabaseValueUtils.asInt(row['subject_id']),
      ),
      'weekday': DatabaseValueUtils.asInt(row['weekday']),
      'start_time': row['start_time'] as String? ?? '08:00',
      'end_time': row['end_time'] as String? ?? '09:00',
      'room': row['room'] as String? ?? '',
      'type': row['type'] as String? ?? 'Lecture',
    };
  }

  Map<String, Object?> _deadlinePayload(
    Map<String, Object?> row,
    String userId,
  ) {
    return <String, Object?>{
      'id': UserScope.mapLegacyId(userId, DatabaseValueUtils.asInt(row['id'])),
      'subject_id': row['subject_id'] == null
          ? null
          : UserScope.mapLegacyId(
              userId,
              DatabaseValueUtils.asInt(row['subject_id']),
            ),
      'title': row['title'] as String? ?? '',
      'description': row['description'] as String? ?? '',
      'due_date': row['due_date'] as String? ?? '',
      'due_time': row['due_time'] as String?,
      'priority': row['priority'] as String? ?? 'Medium',
      'status': row['status'] as String? ?? 'Planned',
      'progress': DatabaseValueUtils.asInt(row['progress']),
    };
  }

  Map<String, Object?> _studyPlanPayload(
    Map<String, Object?> row,
    String userId,
  ) {
    return <String, Object?>{
      'id': UserScope.mapLegacyId(userId, DatabaseValueUtils.asInt(row['id'])),
      'subject_id': row['subject_id'] == null
          ? null
          : UserScope.mapLegacyId(
              userId,
              DatabaseValueUtils.asInt(row['subject_id']),
            ),
      'title': row['title'] as String? ?? '',
      'plan_date': row['plan_date'] as String? ?? '',
      'start_time': row['start_time'] as String?,
      'end_time': row['end_time'] as String?,
      'duration': DatabaseValueUtils.asInt(row['duration'], fallback: 60),
      'topic': row['topic'] as String? ?? '',
      'status': row['status'] as String? ?? 'Planned',
    };
  }

  Map<String, Object?> _pomodoroPayload(
    Map<String, Object?> row,
    String userId,
  ) {
    final DateTime? completedAt = DateTimeUtils.tryParse(row['completed_at']);
    return <String, Object?>{
      'id': UserScope.mapLegacyId(userId, DatabaseValueUtils.asInt(row['id'])),
      'subject_id': row['subject_id'] == null
          ? null
          : UserScope.mapLegacyId(
              userId,
              DatabaseValueUtils.asInt(row['subject_id']),
            ),
      'session_date': row['session_date'] as String? ?? '',
      'duration': DatabaseValueUtils.asInt(row['duration']),
      'type': row['type'] as String? ?? 'Focus',
      'completed_at': completedAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, Object?> _notePayload(Map<String, Object?> row, String userId) {
    final DateTime now = DateTime.now();
    final DateTime createdAt =
        DateTimeUtils.tryParse(row['created_at']) ?? now;
    final DateTime updatedAt =
        DateTimeUtils.tryParse(row['updated_at']) ?? createdAt;
    return <String, Object?>{
      'id': UserScope.mapLegacyId(userId, DatabaseValueUtils.asInt(row['id'])),
      'subject_id': row['subject_id'] == null
          ? null
          : UserScope.mapLegacyId(
              userId,
              DatabaseValueUtils.asInt(row['subject_id']),
            ),
      'title': row['title'] as String? ?? '',
      'content': row['content'] as String? ?? '',
      'color': row['color'] as String? ?? '#2563EB',
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, Object?> _notificationPayload(
    Map<String, Object?> row,
    String userId,
  ) {
    final DateTime? scheduledAt = DateTimeUtils.tryParse(row['scheduled_at']);
    final int? relatedId = DatabaseValueUtils.asNullableInt(row['related_id']);
    return <String, Object?>{
      'id': UserScope.mapLegacyId(userId, DatabaseValueUtils.asInt(row['id'])),
      'type': row['type'] as String? ?? 'general',
      'title': row['title'] as String? ?? '',
      'message': row['message'] as String? ?? '',
      'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
      'is_read': DatabaseValueUtils.asBool(row['is_read']),
      'related_id': relatedId == null
          ? null
          : UserScope.mapLegacyId(userId, relatedId),
    };
  }
}

class LegacyMigrationSummary {
  const LegacyMigrationSummary({
    required this.imported,
    required this.reason,
    this.importedCounts = const <String, int>{},
  });

  final bool imported;
  final String reason;
  final Map<String, int> importedCounts;
}

class _LegacySnapshot {
  const _LegacySnapshot({
    required this.semesters,
    required this.subjects,
    required this.schedules,
    required this.deadlines,
    required this.studyPlans,
    required this.pomodoroSessions,
    required this.notes,
    required this.notifications,
    required this.userSettings,
  });

  final List<Map<String, Object?>> semesters;
  final List<Map<String, Object?>> subjects;
  final List<Map<String, Object?>> schedules;
  final List<Map<String, Object?>> deadlines;
  final List<Map<String, Object?>> studyPlans;
  final List<Map<String, Object?>> pomodoroSessions;
  final List<Map<String, Object?>> notes;
  final List<Map<String, Object?>> notifications;
  final Map<String, Object?>? userSettings;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
