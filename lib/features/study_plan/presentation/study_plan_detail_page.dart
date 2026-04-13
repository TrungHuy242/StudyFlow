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
      if (subject.id == _plan.subjectId) {
        return subject;
      }
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
    final StudyPlanModel? updated =
        await Navigator.of(context).push<StudyPlanModel>(
      MaterialPageRoute<StudyPlanModel>(
        builder: (BuildContext context) => StudyPlanEditorPage(
          subjects: widget.subjects,
          initialValue: _plan,
        ),
      ),
    );
    if (updated == null) {
      return;
    }
    await widget.repository.savePlan(updated);
    final int? updatedId = updated.id;
    if (updatedId == null) {
      return;
    }
    final StudyPlanModel? refreshed =
        await widget.repository.getPlanById(updatedId);
    if (!mounted || refreshed == null) {
      return;
    }
    context.read<AppRefreshNotifier>().markDirty();
    setState(() {
      _plan = refreshed;
    });
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
    final int? updatedId = updated.id;
    if (updatedId == null) {
      return;
    }
    final StudyPlanModel? refreshed =
        await widget.repository.getPlanById(updatedId);
    if (!mounted || refreshed == null) {
      return;
    }
    context.read<AppRefreshNotifier>().markDirty();
    setState(() {
      _plan = refreshed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final SubjectModel? subject = _subject;
    final Color accent = subject?.displayColor ?? StudyFlowPalette.indigo;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              color: accent,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      StudyFlowCircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        size: 42,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        foregroundColor: Colors.white,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          DateTimeUtils.toDbDate(_plan.planDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _plan.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _plan.subjectName ?? 'Chung',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.80),
                          fontSize: 16,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _TimeSummaryCard(plan: _plan),
                  const SizedBox(height: 26),
                  Text(
                    'Chủ đề cần ôn tập',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ..._topics.map((String topic) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: StudyFlowPalette.surfaceSoft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                topic,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: const Color(0xFF334155),
                                      fontSize: 16,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StudyFlowGradientButton(
                          label: 'Bắt đầu học',
                          onTap: () => context.push('/pomodoro'),
                          height: 54,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SecondaryButton(
                          label: _plan.status == 'Done'
                              ? 'Đã hoàn thành'
                              : 'Đánh dấu hoàn\nthành',
                          onTap: _plan.status == 'Done' ? null : _markComplete,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StudyFlowOutlineButton(
                    label: 'Sửa kế hoạch',
                    onTap: _edit,
                    height: 52,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSummaryCard extends StatelessWidget {
  const _TimeSummaryCard({required this.plan});

  final StudyPlanModel plan;

  @override
  Widget build(BuildContext context) {
    final int hours = plan.duration ~/ 60;
    final int minutes = plan.duration % 60;
    final String durationLabel =
        minutes == 0 ? '$hours giờ ôn tập' : '$hours giờ $minutes phút ôn tập';
    return StudyFlowSurfaceCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            plan.timeLabel,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            durationLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: StudyFlowPalette.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onTap == null
                ? const Color(0xFF94A3B8)
                : const Color(0xFF334155),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
