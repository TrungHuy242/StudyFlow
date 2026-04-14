import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/state/app_refresh_notifier.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../analytics/data/analytics_aggregation_service.dart';
import '../../auth/application/app_session_controller.dart';
import '../../deadlines/data/deadline_repository.dart';
import '../../pomodoro/data/pomodoro_repository.dart';
import '../../study_plan/data/study_plan_repository.dart';
import '../../subjects/data/subject_repository.dart';
import '../data/user_settings_model.dart';
import 'profile_app_settings_page.dart';
import 'profile_change_password_page.dart';
import 'profile_edit_page.dart';
import 'profile_notification_settings_page.dart';
import 'profile_theme_page.dart';
import 'widgets/profile_components.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AnalyticsAggregationService? _analyticsService;
  AppRefreshNotifier? _refreshNotifier;
  Future<AnalyticsSummary>? _future;

  void _ensureInitialized() {
    _analyticsService ??= AnalyticsAggregationService(
      pomodoroRepository: PomodoroRepository(context.read<DatabaseService>()),
      deadlineRepository: DeadlineRepository(context.read<DatabaseService>()),
      studyPlanRepository: StudyPlanRepository(context.read<DatabaseService>()),
      subjectRepository: SubjectRepository(context.read<DatabaseService>()),
    );

    final AppRefreshNotifier refreshNotifier =
        context.read<AppRefreshNotifier>();
    if (!identical(_refreshNotifier, refreshNotifier)) {
      _refreshNotifier?.removeListener(_handleExternalRefresh);
      _refreshNotifier = refreshNotifier;
      _refreshNotifier!.addListener(_handleExternalRefresh);
    }

    _future ??= _analyticsService!.loadSummary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureInitialized();
  }

  @override
  void dispose() {
    _refreshNotifier?.removeListener(_handleExternalRefresh);
    super.dispose();
  }

  void _handleExternalRefresh() {
    if (!mounted) {
      return;
    }
    _refresh();
  }

  Future<void> _refresh() async {
    _ensureInitialized();
    final AnalyticsAggregationService? analyticsService = _analyticsService;
    if (analyticsService == null) {
      return;
    }
    setState(() {
      _future = analyticsService.loadSummary();
    });
    await _future;
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => page,
      ),
    );
    if (!mounted) {
      return;
    }
    await _refresh();
  }

  Future<void> _logout() async {
    final AppSessionController sessionController =
        context.read<AppSessionController>();
    final bool confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Đăng xuất?',
      message: 'Bạn có thể đăng nhập lại bằng email và mật khẩu hiện tại.',
      confirmLabel: 'Đăng xuất',
      cancelLabel: 'Hủy',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    await sessionController.logout();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitialized();
    final UserSettingsModel? settings =
        context.watch<AppSessionController>().settings;
    if (settings == null) {
      return const AppLoadingState(message: 'Đang tải hồ sơ...');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FutureBuilder<AnalyticsSummary>(
        future: _future ?? _analyticsService?.loadSummary(),
        builder: (
          BuildContext context,
          AsyncSnapshot<AnalyticsSummary> snapshot,
        ) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState(message: 'Đang tải hồ sơ...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Không thể tải hồ sơ',
              message: 'Hãy thử làm mới để cập nhật thống kê hồ sơ.',
              onAction: _refresh,
            );
          }

          final AnalyticsSummary summary = snapshot.data ??
              AnalyticsSummary(
                focusMinutesThisWeek: 0,
                totalFocusMinutes: 0,
                completedDeadlines: 0,
                overdueDeadlines: 0,
                openDeadlines: 0,
                plannedSessionsThisWeek: 0,
                focusByDay: <DailyFocusData>[],
                deadlineBreakdown: <String, double>{},
                subjectProgress: <SubjectProgressData>[],
                currentStreakDays: 0,
                bestStreakDays: 0,
                daysToNextRecord: 1,
                activeWeekdays: <int>{},
                activeStudyDays: <DateTime>{},
                achievements: <AchievementData>[],
                deadlineCompletionRate: 0,
              );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: <Widget>[
                _ProfileHero(settings: settings, summary: summary),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _ProfileInfoCard(
                        label: 'Mã sinh viên',
                        value: profileStudentId(settings),
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 14),
                      _ProfileInfoCard(
                        label: 'Ngày tham gia',
                        value: profileJoinDate(settings),
                        icon: Icons.calendar_today_outlined,
                      ),
                      const SizedBox(height: 22),
                      ProfileMenuRow(
                        title: 'Chỉnh sửa hồ sơ',
                        icon: Icons.person_outline_rounded,
                        onTap: () => _openPage(const ProfileEditPage()),
                      ),
                      const SizedBox(height: 12),
                      ProfileMenuRow(
                        title: 'Cài đặt thông báo',
                        icon: Icons.notifications_none_rounded,
                        onTap: () =>
                            _openPage(const ProfileNotificationSettingsPage()),
                      ),
                      const SizedBox(height: 12),
                      ProfileMenuRow(
                        title: 'Giao diện',
                        icon: Icons.light_mode_outlined,
                        onTap: () => _openPage(const ProfileThemePage()),
                      ),
                      const SizedBox(height: 12),
                      ProfileMenuRow(
                        title: 'Cài đặt ứng dụng',
                        icon: Icons.tune_rounded,
                        onTap: () => _openPage(const ProfileAppSettingsPage()),
                      ),
                      const SizedBox(height: 12),
                      ProfileMenuRow(
                        title: 'Đổi mật khẩu',
                        icon: Icons.lock_outline_rounded,
                        onTap: () =>
                            _openPage(const ProfileChangePasswordPage()),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _logout,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: const Center(
                            child: Text(
                              'Đăng xuất',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.settings,
    required this.summary,
  });

  final UserSettingsModel settings;
  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            height: 270,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF0F172A),
                  Color(0xFF1E3A8A),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Hồ sơ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: <Widget>[
                        ProfileAvatarBadge(
                          name: settings.displayName,
                          size: 64,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                settings.displayName.isEmpty
                                    ? 'Nguyễn Văn Sinh Viên'
                                    : settings.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                settings.email.isEmpty
                                    ? 'student@university.edu.vn'
                                    : settings.email,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _ProfileStatItem(
                      value: '🔥 ${summary.currentStreakDays}',
                      label: 'Ngày streak',
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProfileStatItem(
                      value: '${summary.completedDeadlines}',
                      label: 'Deadline',
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProfileStatItem(
                      value: _profileHourLabel(summary.totalFocusMinutes),
                      label: 'Giờ học',
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  const _ProfileStatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _profileHourLabel(int minutes) {
  if (minutes <= 0) {
    return '0 h';
  }
  final double hours = minutes / 60;
  final bool isWhole = hours == hours.roundToDouble();
  return isWhole ? '${hours.toInt()} h' : '${hours.toStringAsFixed(1)} h';
}
