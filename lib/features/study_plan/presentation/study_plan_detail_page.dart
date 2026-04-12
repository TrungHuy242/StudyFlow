import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_refresh_notifier.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../subjects/data/subject_model.dart';
import '../data/study_plan_model.dart';
import '../data/study_plan_repository.dart';
import 'study_plan_editor_page.dart';

class StudyPlanDetailPage extends StatefulWidget {
  const StudyPlanDetailPage({
    super.key,
    required this.plan,
    required this.repository,
    required this.subjects,
  });

  final StudyPlanModel plan;
  final StudyPlanRepository repository;
  final List<SubjectModel> subjects;

  @override
  State<StudyPlanDetailPage> createState() => _StudyPlanDetailPageState();
}

class _StudyPlanDetailPageState extends State<StudyPlanDetailPage> {
  late StudyPlanModel _plan;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
  }

  SubjectModel? get _subject {
    for (final SubjectModel subject in widget.subjects) {
      if (subject.id == _plan.subjectId) return subject;
    }
    return null;
  }

  List<String> get _topics {
    return _plan.topic
        .split(',')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _edit() async {
    final StudyPlanModel? updated = await Navigator.of(context).push<StudyPlanModel>(
      MaterialPageRoute<StudyPlanModel>(
        builder: (BuildContext context) => StudyPlanEditorPage(
          subjects: widget.subjects,
          initialValue: _plan,
        ),
      ),
    );
    if (updated == null) return;
    await widget.repository.savePlan(updated);
    final StudyPlanModel? refreshed = await widget.repository.getPlanById(updated.id!);
    if (!mounted || refreshed == null) return;
    context.read<AppRefreshNotifier>().markDirty();
    setState(() => _plan = refreshed);
  }

  Future<void> _markComplete() async {
    final StudyPlanModel updated = StudyPlanModel(
      id: _plan.id,
      subjectId: _plan.subjectId,
      title: _plan.title,
      planDate: _plan.planDate,
      startTime: _plan.startTime,
      endTime: _plan.endTime,
      duration: _plan.duration,
      topic: _plan.topic,
      status: 'Done',
    );
    await widget.repository.savePlan(updated);
    final StudyPlanModel? refreshed = await widget.repository.getPlanById(updated.id!);
    if (!mounted || refreshed == null) return;
    context.read<AppRefreshNotifier>().markDirty();
    setState(() => _plan = refreshed);
  }

  @override
  Widget build(BuildContext context) {
    final SubjectModel? subject = _subject;
    return Scaffold(
      backgroundColor: StudyFlowPalette.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              color: subject?.displayColor ?? StudyFlowPalette.indigo,
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      StudyFlowCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          DateTimeUtils.toDbDate(_plan.planDate),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const StudyFlowIconBadge(
                        icon: Icons.menu_book_rounded,
                        backgroundColor: Colors.white,
                        foregroundColor: StudyFlowPalette.indigo,
                        size: 60,
                        iconSize: 26,
                        borderRadius: 18,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _plan.title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _plan.subjectName ?? 'Chung',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.84)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                children: <Widget>[
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: StudyFlowSurfaceCard(
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: StudyFlowPalette.surfaceSoft,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.schedule_rounded, color: StudyFlowPalette.textMuted),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(_plan.timeLabel, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text('${(_plan.duration / 60).toStringAsFixed(0)} giờ ôn tập', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: StudyFlowPalette.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text('Chủ đề cần ôn tập', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  ..._topics.map((String topic) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(color: StudyFlowPalette.surfaceSoft, borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: <Widget>[
                            const CircleAvatar(radius: 10, backgroundColor: Color(0xFFE3EAF5)),
                            const SizedBox(width: 12),
                            Text(topic, style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StudyFlowGradientButton(
                          label: 'Bắt đầu học',
                          onTap: () => context.push('/pomodoro'),
                          icon: Icons.play_arrow_rounded,
                          height: 52,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SecondaryButton(
                          label: _plan.status == 'Done' ? 'Đã hoàn thành' : 'Đánh dấu hoàn thành',
                          onTap: _plan.status == 'Done' ? null : _markComplete,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StudyFlowOutlineButton(label: 'Sửa kế hoạch', onTap: _edit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: StudyFlowPalette.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onTap == null ? StudyFlowPalette.textMuted : StudyFlowPalette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

