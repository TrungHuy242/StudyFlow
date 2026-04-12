import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_refresh_notifier.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../subjects/data/subject_model.dart';
import '../data/deadline_model.dart';
import '../data/deadline_repository.dart';
import 'deadline_editor_page.dart';

class DeadlineDetailPage extends StatefulWidget {
  const DeadlineDetailPage({
    super.key,
    required this.deadline,
    required this.repository,
    required this.subjects,
  });

  final DeadlineModel deadline;
  final DeadlineRepository repository;
  final List<SubjectModel> subjects;

  @override
  State<DeadlineDetailPage> createState() => _DeadlineDetailPageState();
}

class _DeadlineDetailPageState extends State<DeadlineDetailPage> {
  late DeadlineModel _deadline;

  @override
  void initState() {
    super.initState();
    _deadline = widget.deadline;
  }

  SubjectModel? get _subject {
    for (final SubjectModel subject in widget.subjects) {
      if (subject.id == _deadline.subjectId) {
        return subject;
      }
    }
    return null;
  }

  Future<void> _editDeadline() async {
    final AppRefreshNotifier refreshNotifier = context.read<AppRefreshNotifier>();
    final DeadlineModel? updated = await Navigator.of(context).push<DeadlineModel>(
      MaterialPageRoute<DeadlineModel>(
        builder: (BuildContext context) => DeadlineEditorPage(
          subjects: widget.subjects,
          initialValue: _deadline,
        ),
      ),
    );
    if (updated == null) {
      return;
    }
    await widget.repository.saveDeadline(updated);
    refreshNotifier.markDirty();
    final DeadlineModel? refreshed = await widget.repository.getDeadlineById(updated.id!);
    if (!mounted || refreshed == null) {
      return;
    }
    setState(() {
      _deadline = refreshed;
    });
  }

  Future<void> _deleteDeadline() async {
    if (_deadline.id == null) {
      return;
    }
    final bool confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Xóa deadline?',
      message: 'Deadline này sẽ bị xóa khỏi danh sách theo dõi.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    await widget.repository.deleteDeadline(_deadline.id!);
    if (!mounted) {
      return;
    }
    context.read<AppRefreshNotifier>().markDirty();
    Navigator.of(context).pop(true);
  }

  Future<void> _setProgress(int progress, {String? status}) async {
    final DeadlineModel updated = _deadline.copyWith(
      progress: progress.clamp(0, 100),
      status: status ?? _deadline.status,
    );
    await widget.repository.saveDeadline(updated);
    final DeadlineModel? refreshed = await widget.repository.getDeadlineById(updated.id!);
    if (!mounted || refreshed == null) {
      return;
    }
    context.read<AppRefreshNotifier>().markDirty();
    setState(() {
      _deadline = refreshed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final SubjectModel? subject = _subject;
    return Scaffold(
      backgroundColor: StudyFlowPalette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: <Widget>[
                  StudyFlowCircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  StudyFlowCircleIconButton(
                    icon: Icons.edit_outlined,
                    onTap: _editDeadline,
                  ),
                  const SizedBox(width: 10),
                  StudyFlowCircleIconButton(
                    icon: Icons.delete_outline_rounded,
                    foregroundColor: StudyFlowPalette.coral,
                    onTap: _deleteDeadline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  StudyFlowIconBadge(
                    icon: Icons.menu_book_rounded,
                    backgroundColor: subject?.displayColor ?? StudyFlowPalette.indigo,
                    size: 56,
                    iconSize: 24,
                    borderRadius: 18,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _deadline.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _deadline.subjectName ?? 'Chung',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: StudyFlowPalette.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: StudyFlowSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'Tiến độ',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        Text(
                          '${_deadline.progress} %',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StudyFlowProgressBar(
                      value: _deadline.progress / 100,
                      color: StudyFlowPalette.blue,
                      height: 10,
                      backgroundColor: const Color(0xFFB1C1D8),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _ActionButton(
                            label: 'Cập nhật tiến độ',
                            backgroundColor: const Color(0xFFEFF4FF),
                            foregroundColor: StudyFlowPalette.blue,
                            onTap: () => _setProgress((_deadline.progress + 20).clamp(0, 100)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: 'Hoàn thành',
                            backgroundColor: const Color(0xFFE9F8EE),
                            foregroundColor: StudyFlowPalette.green,
                            onTap: () => _setProgress(100, status: 'Done'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: StudyFlowSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Ngày đến hạn',
                      value: DateTimeUtils.toDbDate(_deadline.dueDate),
                    ),
                    const SizedBox(height: 18),
                    _InfoRow(
                      icon: Icons.schedule_rounded,
                      label: 'Giờ đến hạn',
                      value: _deadline.dueTime ?? '23:59',
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _priorityColor(_deadline.priority).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _priorityLabel(_deadline.priority),
                        style: TextStyle(
                          color: _priorityColor(_deadline.priority),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: StudyFlowSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Mô tả',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _deadline.description.isEmpty
                          ? 'Chưa có mô tả cho deadline này.'
                          : _deadline.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: StudyFlowPalette.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: StudyFlowPalette.surfaceSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 18, color: StudyFlowPalette.textMuted),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: StudyFlowPalette.textSecondary,
                  ),
            ),
            const SizedBox(height: 2),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String _priorityLabel(String priority) {
  switch (priority) {
    case 'High':
      return 'Quan trọng';
    case 'Low':
      return 'Thấp';
    default:
      return 'Bình thường';
  }
}

Color _priorityColor(String priority) {
  switch (priority) {
    case 'High':
      return const Color(0xFFFF6B6B);
    case 'Low':
      return StudyFlowPalette.textMuted;
    default:
      return StudyFlowPalette.orange;
  }
}
