# Cây thư mục rút gọn cho app UI + database chạy Chrome

studyflow_flutter_skeleton/
|-- pubspec.yaml
|-- lib/
|   |-- main.dart
|   |-- web_entrypoint.dart
|   |-- core/
|   |   |-- constants/app_constants.dart
|   |   |-- database/
|   |   |   |-- database_service.dart
|   |   |   |-- database_service_web_impl.dart
|   |   |   |-- database_service_io.dart
|   |   |-- routes/app_router.dart
|   |   |-- state/app_refresh_notifier.dart
|   |   |-- theme/app_theme.dart
|   |   |-- utils/date_time_utils.dart
|   |-- features/
|   |   |-- dashboard/presentation/dashboard_page.dart
|   |   |-- notes/
|   |   |   |-- data/note_repository.dart
|   |   |   |-- presentation/notes_page.dart
|   |   |-- deadlines/
|   |   |   |-- data/deadline_repository.dart
|   |   |   |-- presentation/deadlines_page.dart
|   |   |-- schedule/
|   |   |   |-- data/schedule_repository.dart
|   |   |   |-- presentation/schedule_page.dart
|   |   |   |-- presentation/schedule_detail_page.dart
|   |   |   |-- presentation/schedule_editor_page.dart
|   |   |-- study_plan/
|   |   |   |-- data/study_plan_repository.dart
|   |   |   |-- presentation/study_plan_page.dart
|   |   |   |-- presentation/study_plan_editor_page.dart
|   |   |   |-- presentation/study_plan_detail_page.dart
|   |   |-- pomodoro/
|   |   |   |-- data/pomodoro_repository.dart
|   |   |   |-- presentation/pomodoro_page.dart
|   |   |-- profile/
|   |   |   |-- data/user_settings_repository.dart
|   |   |   |-- presentation/profile_page.dart
|   |-- shared/
|   |   |-- widgets/
|   |   |   |-- studyflow_components.dart
|   |   |   |-- app_stat_tile.dart
|   |   |   |-- app_section_card.dart
|   |   |   |-- app_loading_state.dart
|   |   |   |-- app_error_state.dart
|   |   |   |-- app_empty_state.dart
|   |   |   |-- app_confirm_dialog.dart
|-- web/
|   |-- index.html
|   |-- manifest.json
