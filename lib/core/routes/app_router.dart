import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/presentation/analytics_page.dart';
import '../../features/ai_assistant/presentation/ai_assistant_page.dart';
import '../../features/app_shell/app_shell.dart';
import '../../features/auth/application/app_session_controller.dart';
import '../../features/auth/presentation/auth_flow_payloads.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/otp_verification_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/deadlines/presentation/deadlines_page.dart';
import '../../features/notes/presentation/notes_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/onboarding/presentation/splash_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/pomodoro/presentation/pomodoro_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/schedule/presentation/schedule_detail_page.dart';
import '../../features/schedule/presentation/schedule_editor_page.dart';
import '../../features/schedule/presentation/schedule_page.dart';
import '../../features/semester/presentation/semester_page.dart';
import '../../features/study_plan/presentation/study_plan_page.dart';
import '../../features/subjects/presentation/subject_detail_page.dart';
import '../../features/subjects/presentation/subject_editor_page.dart';
import '../../features/subjects/presentation/subjects_page.dart';

class AppRouter {
  AppRouter(this._sessionController);

  final AppSessionController _sessionController;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    refreshListenable: _sessionController,
    redirect: (BuildContext context, GoRouterState state) {
      if (_sessionController.isLoading) {
        return state.matchedLocation == '/' ? null : '/';
      }

      final String location = state.matchedLocation;
      final bool isSplash = location == '/';
      final bool isOnboarding = location == '/onboarding';
      final bool isAuthFlow = <String>{
        '/login',
        '/register',
        '/verify-email',
        '/forgot-password',
        '/reset-password',
      }.contains(location);

      if (!_sessionController.onboardingDone && !isSplash && !isOnboarding) {
        return '/onboarding';
      }

      if (_sessionController.onboardingDone &&
          !_sessionController.isLoggedIn &&
          !isSplash &&
          !isAuthFlow) {
        return '/login';
      }

      if (_sessionController.isLoggedIn && (isOnboarding || isAuthFlow)) {
        return '/home';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/verify-email',
        builder: (_, GoRouterState state) =>
            OtpVerificationPage(payload: state.extra),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, GoRouterState state) {
          final ResetPasswordDraft? draft = state.extra as ResetPasswordDraft?;
          return ResetPasswordPage(draft: draft);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(path: '/home', builder: (_, __) => const DashboardPage()),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                  path: '/calendar', builder: (_, __) => const SchedulePage()),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                  path: '/deadlines',
                  builder: (_, __) => const DeadlinesPage()),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                  path: '/analytics',
                  builder: (_, __) => const AnalyticsPage()),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                  path: '/profile', builder: (_, __) => const ProfilePage()),
            ],
          ),
        ],
      ),
      GoRoute(path: '/semester', builder: (_, __) => const SemesterPage()),
      GoRoute(path: '/subjects', builder: (_, __) => const SubjectsPage()),
      GoRoute(path: '/study-plan', builder: (_, __) => const StudyPlanPage()),
      GoRoute(
          path: '/calendar/add',
          builder: (_, __) => const ScheduleEditorPage()),
      GoRoute(
        path: '/calendar/:scheduleId',
        builder: (_, GoRouterState state) {
          final int scheduleId =
              int.tryParse(state.pathParameters['scheduleId'] ?? '') ?? 0;
          return ScheduleDetailPage(scheduleId: scheduleId);
        },
      ),
      GoRoute(
        path: '/calendar/:scheduleId/edit',
        builder: (_, GoRouterState state) {
          final int? scheduleId =
              int.tryParse(state.pathParameters['scheduleId'] ?? '');
          return ScheduleEditorPage(scheduleId: scheduleId);
        },
      ),
      GoRoute(
          path: '/subjects/add', builder: (_, __) => const SubjectEditorPage()),
      GoRoute(
        path: '/subjects/:subjectId',
        builder: (_, GoRouterState state) {
          final int subjectId =
              int.tryParse(state.pathParameters['subjectId'] ?? '') ?? 0;
          return SubjectDetailPage(subjectId: subjectId);
        },
      ),
      GoRoute(
        path: '/subjects/:subjectId/edit',
        builder: (_, GoRouterState state) {
          final int? subjectId =
              int.tryParse(state.pathParameters['subjectId'] ?? '');
          return SubjectEditorPage(subjectId: subjectId);
        },
      ),
      GoRoute(path: '/pomodoro', builder: (_, __) => const PomodoroPage()),
      GoRoute(path: '/notes', builder: (_, __) => const NotesPage()),
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsPage()),
      GoRoute(
          path: '/ai-assistant', builder: (_, __) => const AiAssistantPage()),
    ],
  );
}
