import '../../../core/utils/database_value_utils.dart';
import '../../../core/utils/date_time_utils.dart';

class UserSettingsModel {
  const UserSettingsModel({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.avatar,
    required this.studentCode,
    required this.joinedAt,
    required this.darkMode,
    required this.notificationsEnabled,
    required this.onboardingDone,
    required this.focusDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.studyGoalMinutes,
    required this.legacyMigratedAt,
  });

  final String? userId;
  final String displayName;
  final String email;
  final String? avatar;
  final String? studentCode;
  final DateTime? joinedAt;
  final bool darkMode;
  final bool notificationsEnabled;
  final bool onboardingDone;
  final int focusDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final int studyGoalMinutes;
  final DateTime? legacyMigratedAt;

  bool get isAuthenticated => (userId ?? '').isNotEmpty;

  UserSettingsModel copyWith({
    String? userId,
    String? displayName,
    String? email,
    Object? avatar = _sentinel,
    Object? studentCode = _sentinel,
    Object? joinedAt = _sentinel,
    bool? darkMode,
    bool? notificationsEnabled,
    bool? onboardingDone,
    int? focusDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? studyGoalMinutes,
    Object? legacyMigratedAt = _sentinel,
  }) {
    return UserSettingsModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatar: identical(avatar, _sentinel) ? this.avatar : avatar as String?,
      studentCode: identical(studentCode, _sentinel)
          ? this.studentCode
          : studentCode as String?,
      joinedAt: identical(joinedAt, _sentinel)
          ? this.joinedAt
          : joinedAt as DateTime?,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      focusDuration: focusDuration ?? this.focusDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      studyGoalMinutes: studyGoalMinutes ?? this.studyGoalMinutes,
      legacyMigratedAt: identical(legacyMigratedAt, _sentinel)
          ? this.legacyMigratedAt
          : legacyMigratedAt as DateTime?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': userId,
      'display_name': displayName,
      'email': email,
      'avatar': avatar,
      'student_code': studentCode,
      'joined_at': joinedAt?.toUtc().toIso8601String(),
      'dark_mode': darkMode,
      'notifications_enabled': notificationsEnabled,
      'onboarding_done': onboardingDone,
      'focus_duration': focusDuration,
      'short_break_duration': shortBreakDuration,
      'long_break_duration': longBreakDuration,
      'study_goal_minutes': studyGoalMinutes,
      'legacy_migrated_at': legacyMigratedAt?.toUtc().toIso8601String(),
    };
  }

  factory UserSettingsModel.fromMap(Map<String, Object?> map) {
    return UserSettingsModel(
      userId: map['id'] as String? ?? map['user_id'] as String?,
      displayName: map['display_name'] as String? ?? 'Student',
      email: map['email'] as String? ?? '',
      avatar: map['avatar'] as String?,
      studentCode: map['student_code'] as String?,
      joinedAt: DateTimeUtils.tryParse(map['joined_at']),
      darkMode: DatabaseValueUtils.asBool(map['dark_mode']),
      notificationsEnabled:
          DatabaseValueUtils.asBool(map['notifications_enabled'], fallback: true),
      onboardingDone: DatabaseValueUtils.asBool(map['onboarding_done']),
      focusDuration:
          DatabaseValueUtils.asInt(map['focus_duration'], fallback: 25),
      shortBreakDuration:
          DatabaseValueUtils.asInt(map['short_break_duration'], fallback: 5),
      longBreakDuration:
          DatabaseValueUtils.asInt(map['long_break_duration'], fallback: 15),
      studyGoalMinutes:
          DatabaseValueUtils.asInt(map['study_goal_minutes'], fallback: 120),
      legacyMigratedAt: DateTimeUtils.tryParse(map['legacy_migrated_at']),
    );
  }
}

const Object _sentinel = Object();
