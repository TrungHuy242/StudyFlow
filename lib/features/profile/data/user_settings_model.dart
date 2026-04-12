class UserSettingsModel {
  const UserSettingsModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.avatar,
    required this.darkMode,
    required this.notificationsEnabled,
    required this.onboardingDone,
    required this.localPassword,
    required this.isLoggedIn,
    required this.focusDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.studyGoalMinutes,
  });

  final int id;
  final String displayName;
  final String email;
  final String? avatar;
  final bool darkMode;
  final bool notificationsEnabled;
  final bool onboardingDone;
  final String? localPassword;
  final bool isLoggedIn;
  final int focusDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final int studyGoalMinutes;

  bool get hasLocalAccount =>
      email.trim().isNotEmpty && (localPassword?.isNotEmpty ?? false);

  UserSettingsModel copyWith({
    int? id,
    String? displayName,
    String? email,
    String? avatar,
    bool? darkMode,
    bool? notificationsEnabled,
    bool? onboardingDone,
    String? localPassword,
    bool? isLoggedIn,
    int? focusDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? studyGoalMinutes,
  }) {
    return UserSettingsModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      localPassword: localPassword ?? this.localPassword,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      focusDuration: focusDuration ?? this.focusDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      studyGoalMinutes: studyGoalMinutes ?? this.studyGoalMinutes,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'display_name': displayName,
      'email': email,
      'avatar': avatar,
      'dark_mode': darkMode ? 1 : 0,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'onboarding_done': onboardingDone ? 1 : 0,
      'local_password': localPassword,
      'is_logged_in': isLoggedIn ? 1 : 0,
      'focus_duration': focusDuration,
      'short_break_duration': shortBreakDuration,
      'long_break_duration': longBreakDuration,
      'study_goal_minutes': studyGoalMinutes,
    };
  }

  factory UserSettingsModel.fromMap(Map<String, Object?> map) {
    return UserSettingsModel(
      id: map['id'] as int? ?? 1,
      displayName: map['display_name'] as String? ?? 'Student',
      email: map['email'] as String? ?? '',
      avatar: map['avatar'] as String?,
      darkMode: (map['dark_mode'] as int? ?? 0) == 1,
      notificationsEnabled: (map['notifications_enabled'] as int? ?? 1) == 1,
      onboardingDone: (map['onboarding_done'] as int? ?? 0) == 1,
      localPassword: map['local_password'] as String?,
      isLoggedIn: (map['is_logged_in'] as int? ?? 0) == 1,
      focusDuration: map['focus_duration'] as int? ?? 25,
      shortBreakDuration: map['short_break_duration'] as int? ?? 5,
      longBreakDuration: map['long_break_duration'] as int? ?? 15,
      studyGoalMinutes: map['study_goal_minutes'] as int? ?? 120,
    );
  }
}
