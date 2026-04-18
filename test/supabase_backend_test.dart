// ignore_for_file: unnecessary_overrides

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studyflow/core/data/user_scope.dart';
import 'package:studyflow/core/database/database_service.dart';
import 'package:studyflow/core/migration/legacy_sqlite_migration_service.dart';
import 'package:studyflow/features/auth/application/app_session_controller.dart';
import 'package:studyflow/features/deadlines/data/deadline_model.dart';
import 'package:studyflow/features/deadlines/data/deadline_repository.dart';
import 'package:studyflow/features/notes/data/note_model.dart';
import 'package:studyflow/features/notes/data/note_repository.dart';
import 'package:studyflow/features/notifications/data/notification_item_model.dart';
import 'package:studyflow/features/notifications/data/notification_repository.dart';
import 'package:studyflow/features/pomodoro/data/pomodoro_repository.dart';
import 'package:studyflow/features/pomodoro/data/pomodoro_session_model.dart';
import 'package:studyflow/features/profile/data/user_settings_model.dart';
import 'package:studyflow/features/profile/data/user_settings_repository.dart';
import 'package:studyflow/features/schedule/data/schedule_model.dart';
import 'package:studyflow/features/schedule/data/schedule_repository.dart';
import 'package:studyflow/features/semester/data/semester_model.dart';
import 'package:studyflow/features/semester/data/semester_repository.dart';
import 'package:studyflow/features/study_plan/data/study_plan_model.dart';
import 'package:studyflow/features/study_plan/data/study_plan_repository.dart';
import 'package:studyflow/features/subjects/data/subject_model.dart';
import 'package:studyflow/features/subjects/data/subject_repository.dart';

const bool _runSupabaseBackendTests =
    bool.fromEnvironment('RUN_SUPABASE_BACKEND_TESTS');

void main() {
  if (!_runSupabaseBackendTests) {
    test('Supabase backend tests are skipped by default', () {
      expect(true, isTrue);
    });
    return;
  }

  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  late DatabaseService databaseService;
  late SemesterRepository semesterRepository;
  late SubjectRepository subjectRepository;
  late ScheduleRepository scheduleRepository;
  late DeadlineRepository deadlineRepository;
  late StudyPlanRepository studyPlanRepository;
  late PomodoroRepository pomodoroRepository;
  late NoteRepository noteRepository;
  late NotificationRepository notificationRepository;
  late UserSettingsRepository userSettingsRepository;
  late LegacySqliteMigrationService migrationService;
  late String prefix;
  late String testEmail;
  const String testPassword = 'Password123!';
  late UserSettingsModel originalSettings;
  bool primaryAccountRegistered = false;

  Future<void> cleanupCreatedData() async {
    final client = databaseService.client;
    final String userId = databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    await client
        .from('notifications')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .like('title', '$prefix%');
    await client
        .from('notes')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .like('title', '$prefix%');
    await client
        .from('pomodoro_sessions')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .eq('type', '$prefix-focus');
    await client
        .from('study_plans')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .like('title', '$prefix%');
    await client
        .from('deadlines')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .like('title', '$prefix%');
    await client
        .from('schedules')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .like('type', '$prefix%');
    await client
        .from('subjects')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .like('name', '$prefix%');
    await client
        .from('semesters')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .like('name', '$prefix%');
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await DatabaseService.instance.init();
    databaseService = DatabaseService.instance;
    semesterRepository = SemesterRepository(databaseService);
    subjectRepository = SubjectRepository(databaseService);
    scheduleRepository = ScheduleRepository(databaseService);
    deadlineRepository = DeadlineRepository(databaseService);
    studyPlanRepository = StudyPlanRepository(databaseService);
    pomodoroRepository = PomodoroRepository(databaseService);
    noteRepository = NoteRepository(databaseService);
    notificationRepository = NotificationRepository(databaseService);
    userSettingsRepository = UserSettingsRepository(databaseService);
    migrationService = LegacySqliteMigrationService(databaseService);
    prefix = 'studyflowtest${DateTime.now().millisecondsSinceEpoch}';
    testEmail = '$prefix@example.com';
    await userSettingsRepository.registerAccount(
      displayName: 'Test User',
      studentCode: 'TST123',
      email: testEmail,
      password: testPassword,
    );
    primaryAccountRegistered = true;
    originalSettings = await userSettingsRepository.getSettings();
    await cleanupCreatedData();
  });

  tearDownAll(() async {
    if (!primaryAccountRegistered) {
      return;
    }
    await userSettingsRepository.login(
      email: testEmail,
      password: testPassword,
    );
    await userSettingsRepository.saveSettings(originalSettings);
    await cleanupCreatedData();
    await userSettingsRepository.logout();
  });

  test('semester create/read/update/delete works against Supabase', () async {
    final SemesterModel semester = SemesterModel(
      name: '$prefix semester',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 6, 1),
      isActive: true,
    );

    await semesterRepository.saveSemester(semester);

    final List<SemesterModel> semesters = await semesterRepository.getSemesters();
    final SemesterModel created = semesters.firstWhere(
      (SemesterModel item) => item.name == '$prefix semester',
    );
    expect(created.isActive, isTrue);

    await semesterRepository.saveSemester(
      created.copyWith(name: '$prefix semester updated', isActive: false),
    );

    final List<SemesterModel> updatedSemesters =
        await semesterRepository.getSemesters();
    final SemesterModel updated = updatedSemesters.firstWhere(
      (SemesterModel item) => item.id == created.id,
    );
    expect(updated.name, '$prefix semester updated');

    await semesterRepository.deleteSemester(updated.id!);
    final List<SemesterModel> afterDelete = await semesterRepository.getSemesters();
    expect(
      afterDelete.where((SemesterModel item) => item.id == updated.id),
      isEmpty,
    );
  });

  test('subjects create/read/update/delete works against Supabase', () async {
    final SemesterModel semester = SemesterModel(
      name: '$prefix subject-semester',
      startDate: DateTime(2026, 2, 1),
      endDate: DateTime(2026, 7, 1),
      isActive: true,
    );
    await semesterRepository.saveSemester(semester);
    final SemesterModel createdSemester = (await semesterRepository.getSemesters())
        .firstWhere((SemesterModel item) => item.name == '$prefix subject-semester');

    await subjectRepository.saveSubject(
      SubjectModel(
        semesterId: createdSemester.id,
        name: '$prefix subject',
        code: 'SB101',
        color: '#2563EB',
        credits: 3,
        teacher: 'Teacher',
        room: 'A1-204',
        note: 'Initial note',
      ),
    );

    final SubjectModel created = (await subjectRepository.getSubjects())
        .firstWhere((SubjectModel item) => item.name == '$prefix subject');
    expect(created.room, 'A1-204');
    expect(created.note, 'Initial note');

    await subjectRepository.saveSubject(
      created.copyWith(
        teacher: 'Teacher Updated',
        room: 'B2-301',
        note: 'Updated note',
      ),
    );

    final SubjectModel updated =
        (await subjectRepository.getSubjects()).firstWhere(
      (SubjectModel item) => item.id == created.id,
    );
    expect(updated.teacher, 'Teacher Updated');
    expect(updated.room, 'B2-301');
    expect(updated.note, 'Updated note');

    await subjectRepository.deleteSubject(updated.id!);
    final List<SubjectModel> afterDelete = await subjectRepository.getSubjects();
    expect(
      afterDelete.where((SubjectModel item) => item.id == updated.id),
      isEmpty,
    );
  });

  test('schedule CRUD works against Supabase', () async {
    await subjectRepository.saveSubject(
      SubjectModel(
        semesterId: null,
        name: '$prefix schedule-subject',
        code: 'SC101',
        color: '#0F766E',
        credits: 2,
        teacher: 'Teacher',
        room: 'Room Base',
        note: '',
      ),
    );
    final SubjectModel subject = (await subjectRepository.getSubjects())
        .firstWhere((SubjectModel item) => item.name == '$prefix schedule-subject');

    await scheduleRepository.saveSchedule(
      ScheduleModel(
        subjectId: subject.id!,
        weekday: 2,
        startTime: '08:00',
        endTime: '09:30',
        room: 'C1-101',
        type: '$prefix lecture',
      ),
    );

    final ScheduleModel created = (await scheduleRepository.getSchedules())
        .firstWhere((ScheduleModel item) => item.type == '$prefix lecture');
    expect(created.subjectName, subject.name);

    await scheduleRepository.saveSchedule(
      created.copyWith(room: 'C1-202', endTime: '10:00'),
    );

    final ScheduleModel updated = (await scheduleRepository.getSchedules())
        .firstWhere((ScheduleModel item) => item.id == created.id);
    expect(updated.room, 'C1-202');
    expect(updated.endTime, '10:00');

    await scheduleRepository.deleteSchedule(updated.id!);
    expect(
      (await scheduleRepository.getSchedules())
          .where((ScheduleModel item) => item.id == updated.id),
      isEmpty,
    );
  });

  test('deadlines CRUD/progress/status works against Supabase', () async {
    await subjectRepository.saveSubject(
      SubjectModel(
        semesterId: null,
        name: '$prefix deadline-subject',
        code: 'DL101',
        color: '#EA580C',
        credits: 4,
        teacher: 'Teacher',
        room: '',
        note: '',
      ),
    );
    final SubjectModel subject = (await subjectRepository.getSubjects())
        .firstWhere((SubjectModel item) => item.name == '$prefix deadline-subject');

    await deadlineRepository.saveDeadline(
      DeadlineModel(
        subjectId: subject.id,
        title: '$prefix deadline',
        description: 'Desc',
        dueDate: DateTime(2026, 5, 1),
        dueTime: '23:15',
        priority: 'High',
        status: 'Planned',
        progress: 25,
      ),
    );

    final DeadlineModel created = (await deadlineRepository.getDeadlines())
        .firstWhere((DeadlineModel item) => item.title == '$prefix deadline');
    expect(created.subjectName, subject.name);
    expect(created.progress, 25);

    await deadlineRepository.saveDeadline(
      created.copyWith(status: 'Done', progress: 100),
    );

    final DeadlineModel updated = (await deadlineRepository.getDeadlines())
        .firstWhere((DeadlineModel item) => item.id == created.id);
    expect(updated.isDone, isTrue);
    expect(updated.progress, 100);

    await deadlineRepository.deleteDeadline(updated.id!);
    expect(
      (await deadlineRepository.getDeadlines())
          .where((DeadlineModel item) => item.id == updated.id),
      isEmpty,
    );
  });

  test('study plans CRUD works against Supabase', () async {
    await subjectRepository.saveSubject(
      SubjectModel(
        semesterId: null,
        name: '$prefix plan-subject',
        code: 'PL101',
        color: '#7C3AED',
        credits: 3,
        teacher: 'Teacher',
        room: '',
        note: '',
      ),
    );
    final SubjectModel subject = (await subjectRepository.getSubjects())
        .firstWhere((SubjectModel item) => item.name == '$prefix plan-subject');

    await studyPlanRepository.savePlan(
      StudyPlanModel(
        subjectId: subject.id,
        title: '$prefix study-plan',
        planDate: DateTime(2026, 5, 2),
        startTime: '19:00',
        endTime: '21:00',
        duration: 120,
        topic: 'Topic A',
        status: 'Planned',
      ),
    );

    final StudyPlanModel created = (await studyPlanRepository.getPlans())
        .firstWhere((StudyPlanModel item) => item.title == '$prefix study-plan');
    expect(created.subjectName, subject.name);

    await studyPlanRepository.savePlan(
      StudyPlanModel(
        id: created.id,
        subjectId: created.subjectId,
        subjectName: created.subjectName,
        subjectColor: created.subjectColor,
        title: created.title,
        planDate: created.planDate,
        startTime: '20:00',
        endTime: '21:30',
        duration: 90,
        topic: 'Topic B',
        status: 'Done',
      ),
    );

    final StudyPlanModel updated = (await studyPlanRepository.getPlans())
        .firstWhere((StudyPlanModel item) => item.id == created.id);
    expect(updated.status, 'Done');
    expect(updated.duration, 90);

    await studyPlanRepository.deletePlan(updated.id!);
    expect(
      (await studyPlanRepository.getPlans())
          .where((StudyPlanModel item) => item.id == updated.id),
      isEmpty,
    );
  });

  test('pomodoro sessions persist and can be read back from Supabase', () async {
    await subjectRepository.saveSubject(
      SubjectModel(
        semesterId: null,
        name: '$prefix pomodoro-subject',
        code: 'PO101',
        color: '#16A34A',
        credits: 3,
        teacher: 'Teacher',
        room: '',
        note: '',
      ),
    );
    final SubjectModel subject = (await subjectRepository.getSubjects())
        .firstWhere((SubjectModel item) => item.name == '$prefix pomodoro-subject');

    await pomodoroRepository.saveSession(
      PomodoroSessionModel(
        subjectId: subject.id,
        sessionDate: DateTime(2026, 5, 3),
        duration: 25,
        type: '$prefix-focus',
        completedAt: DateTime(2026, 5, 3, 9, 30),
      ),
    );

    final PomodoroSessionModel created = (await pomodoroRepository.getSessions())
        .firstWhere((PomodoroSessionModel item) => item.type == '$prefix-focus');
    expect(created.subjectName, subject.name);
    expect(created.duration, 25);
  });

  test('notes CRUD works against Supabase', () async {
    await subjectRepository.saveSubject(
      SubjectModel(
        semesterId: null,
        name: '$prefix note-subject',
        code: 'NT101',
        color: '#0891B2',
        credits: 3,
        teacher: 'Teacher',
        room: '',
        note: '',
      ),
    );
    final SubjectModel subject = (await subjectRepository.getSubjects())
        .firstWhere((SubjectModel item) => item.name == '$prefix note-subject');

    final DateTime now = DateTime.now();
    await noteRepository.saveNote(
      NoteModel(
        subjectId: subject.id,
        title: '$prefix note',
        content: 'Content A',
        color: '#0891B2',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final NoteModel created = (await noteRepository.getNotes())
        .firstWhere((NoteModel item) => item.title == '$prefix note');
    expect(created.subjectName, subject.name);

    await noteRepository.saveNote(
      NoteModel(
        id: created.id,
        subjectId: created.subjectId,
        subjectName: created.subjectName,
        title: created.title,
        content: 'Content B',
        color: created.color,
        createdAt: created.createdAt,
        updatedAt: DateTime.now(),
      ),
    );

    final NoteModel updated = (await noteRepository.getNotes())
        .firstWhere((NoteModel item) => item.id == created.id);
    expect(updated.content, 'Content B');

    await noteRepository.deleteNote(updated.id!);
    expect(
      (await noteRepository.getNotes()).where((NoteModel item) => item.id == updated.id),
      isEmpty,
    );
  });

  test('notifications metadata persists against Supabase', () async {
    final NotificationItemModel saved = await notificationRepository.saveNotification(
      NotificationItemModel(
        type: 'general',
        title: '$prefix reminder',
        message: 'Check reminder',
        scheduledAt: DateTime(2026, 5, 4, 10, 0),
        isRead: true,
        relatedId: null,
      ),
    );

    final NotificationItemModel created =
        (await notificationRepository.getNotifications()).firstWhere(
      (NotificationItemModel item) => item.id == saved.id,
    );
    expect(created.title, '$prefix reminder');
    expect(created.isEnabled, isTrue);

    await notificationRepository.markRead(created.id!, false);
    final NotificationItemModel updated =
        (await notificationRepository.getNotifications()).firstWhere(
      (NotificationItemModel item) => item.id == created.id,
    );
    expect(updated.isEnabled, isFalse);

    await notificationRepository.deleteNotification(updated.id!);
    expect(
      (await notificationRepository.getNotifications())
          .where((NotificationItemModel item) => item.id == updated.id),
      isEmpty,
    );
  });

  test('user settings persist against Supabase', () async {
    final UserSettingsModel updated = await userSettingsRepository.saveSettings(
      originalSettings.copyWith(
        displayName: '$prefix user',
        darkMode: !originalSettings.darkMode,
        notificationsEnabled: !originalSettings.notificationsEnabled,
        focusDuration: 30,
        shortBreakDuration: 10,
        longBreakDuration: 20,
        studyGoalMinutes: 150,
      ),
    );

    expect(updated.displayName, '$prefix user');
    expect(updated.focusDuration, 30);
    expect(updated.studyGoalMinutes, 150);

    final UserSettingsModel reloaded = await userSettingsRepository.getSettings();
    expect(reloaded.displayName, '$prefix user');
    expect(reloaded.longBreakDuration, 20);
  });

  test('app startup/session hydration works against Supabase settings', () async {
    final AppSessionController controller =
        AppSessionController(userSettingsRepository, migrationService);
    await controller.hydrate();
    expect(controller.isLoading, isFalse);
    expect(controller.settings, isNotNull);
    expect(controller.settings!.userId, databaseService.currentUserId);
  });

  test('multiple Supabase accounts keep separate settings rows', () async {
    final UserSettingsModel firstUserSettings =
        await userSettingsRepository.saveSettings(
      originalSettings.copyWith(
        displayName: '$prefix first-user',
        darkMode: true,
        focusDuration: 35,
      ),
    );

    final String secondEmail = '${prefix}_second@example.com';
    const String secondPassword = 'Password123!';

    final UserSettingsModel secondUserSettings =
        await userSettingsRepository.registerAccount(
      displayName: 'Second User',
      studentCode: 'TST456',
      email: secondEmail,
      password: secondPassword,
    );

    final UserSettingsModel savedSecondSettings =
        await userSettingsRepository.saveSettings(
      secondUserSettings.copyWith(
        displayName: '$prefix second-user',
        darkMode: false,
        focusDuration: 50,
      ),
    );

    await userSettingsRepository.logout();
    await userSettingsRepository.login(
      email: testEmail,
      password: testPassword,
    );

    final UserSettingsModel reloadedFirstUser =
        await userSettingsRepository.getSettings();
    expect(reloadedFirstUser.email, testEmail);
    expect(reloadedFirstUser.displayName, firstUserSettings.displayName);
    expect(reloadedFirstUser.focusDuration, firstUserSettings.focusDuration);
    expect(reloadedFirstUser.darkMode, firstUserSettings.darkMode);

    await userSettingsRepository.logout();
    await userSettingsRepository.login(
      email: secondEmail,
      password: secondPassword,
    );

    final UserSettingsModel reloadedSecondUser =
        await userSettingsRepository.getSettings();
    expect(reloadedSecondUser.email, secondEmail);
    expect(reloadedSecondUser.displayName, savedSecondSettings.displayName);
    expect(reloadedSecondUser.focusDuration, savedSecondSettings.focusDuration);
    expect(reloadedSecondUser.studentCode, 'TST456');
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}
