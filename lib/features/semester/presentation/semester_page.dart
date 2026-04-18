import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/state/app_refresh_notifier.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../data/semester_model.dart';
import '../data/semester_repository.dart';

class SemesterPage extends StatefulWidget {
  const SemesterPage({super.key});

  @override
  State<SemesterPage> createState() => _SemesterPageState();
}

class _SemesterPageState extends State<SemesterPage> {
  late final SemesterRepository _repository;
  late final AppRefreshNotifier _refreshNotifier;
  late Future<List<SemesterModel>> _future;
  final TextEditingController _nameController = TextEditingController();
  int _step = 0;
  DateTime _startDate = DateTime(2026, 1, 5);
  DateTime _endDate = DateTime(2026, 5, 15);
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _repository = SemesterRepository(context.read<DatabaseService>());
    _refreshNotifier = context.read<AppRefreshNotifier>();
    _future = _repository.getSemesters();
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyPreset(SemesterModel semester) {
    setState(() {
      _nameController.text = semester.name;
      _startDate = semester.startDate;
      _endDate = semester.endDate;
    });
  }

  void _shiftDate({required bool start, required int direction}) {
    setState(() {
      if (start) {
        _startDate = _startDate.add(Duration(days: direction));
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = _endDate.add(Duration(days: direction));
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      }
    });
  }

  Future<void> _saveSemester() async {
    final String name = _nameController.text.trim().isEmpty
        ? 'Học kỳ ${DateTime.now().year}'
        : _nameController.text.trim();
    await _repository.saveSemester(
      SemesterModel(
        name: name,
        startDate: _startDate,
        endDate: _endDate,
        isActive: true,
      ),
    );
    _refreshNotifier.markDirty();
    if (!mounted) return;
    context.go('/subjects');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<SemesterModel>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<SemesterModel>> snapshot) {
          final List<SemesterModel> semesters = snapshot.data ?? <SemesterModel>[];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  StudyFlowCircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: _step == 0 ? () => context.pop() : () => setState(() => _step -= 1),
                  ),
                  const SizedBox(height: 24),
                  StudyFlowIconBadge(
                    icon: _step == 1 ? Icons.calendar_month_rounded : Icons.school_outlined,
                    backgroundColor: _step == 2 ? StudyFlowPalette.green : StudyFlowPalette.indigo,
                  ),
                  const SizedBox(height: 22),
                  if (_step == 0) ...<Widget>[
                    Text('Thiết lập học kỳ', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Chọn hoặc tạo học kỳ mới để bắt đầu',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 26),
                    Text('Chọn nhanh', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 14),
                    ...semesters.take(3).map(
                      (SemesterModel semester) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _applyPreset(semester),
                          borderRadius: BorderRadius.circular(18),
                          child: StudyFlowSurfaceCard(
                            child: Row(
                              children: <Widget>[
                                const StudyFlowIconBadge(
                                  icon: Icons.calendar_today_rounded,
                                  backgroundColor: Color(0xFFF1F5FB),
                                  foregroundColor: StudyFlowPalette.textSecondary,
                                  size: 40,
                                  iconSize: 18,
                                  borderRadius: 12,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(semester.name),
                                      const SizedBox(height: 4),
                                      Text(semester.dateRangeLabel, style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(child: Text('hoặc', style: Theme.of(context).textTheme.bodyMedium)),
                    const SizedBox(height: 16),
                    StudyFlowInput(
                      controller: _nameController,
                      hintText: 'VD: Học kỳ 2 - 2025/2026',
                    ),
                    const Spacer(),
                    StudyFlowGradientButton(
                      label: 'Tiếp tục',
                      onTap: () => setState(() {
                        if (_nameController.text.trim().isEmpty) {
                          _nameController.text = 'Học kỳ 2 - 2025/2026';
                        }
                        _step = 1;
                      }),
                    ),
                  ] else if (_step == 1) ...<Widget>[
                    Text('Chọn thời gian', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Đặt ngày bắt đầu và kết thúc học kỳ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 26),
                    _DateCard(
                      title: 'Ngày bắt đầu',
                      day: _startDate.day.toString(),
                      month: 'Tháng ${_startDate.month}',
                      onPrevious: () => _shiftDate(start: true, direction: -1),
                      onNext: () => _shiftDate(start: true, direction: 1),
                    ),
                    const SizedBox(height: 14),
                    _DateCard(
                      title: 'Ngày kết thúc',
                      day: _endDate.day.toString(),
                      month: 'Tháng ${_endDate.month}',
                      onPrevious: () => _shiftDate(start: false, direction: -1),
                      onNext: () => _shiftDate(start: false, direction: 1),
                    ),
                    const SizedBox(height: 14),
                    StudyFlowSurfaceCard(
                      color: const Color(0xFFF7F4FF),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: _OverviewMetric(value: '${_endDate.difference(_startDate).inDays ~/ 7}', label: 'Tuần')),
                          Expanded(child: _OverviewMetric(value: '${_endDate.difference(_startDate).inDays}', label: 'Ngày')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    StudyFlowSurfaceCard(
                      child: Column(
                        children: <Widget>[
                          _SummaryRow(label: 'Ngày bắt đầu:', value: DateTimeUtils.formatSlashDate(_startDate)),
                          const SizedBox(height: 12),
                          _SummaryRow(label: 'Ngày kết thúc:', value: DateTimeUtils.formatSlashDate(_endDate)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: StudyFlowOutlineButton(
                            label: 'Quay lại',
                            onTap: () => setState(() => _step = 0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StudyFlowGradientButton(
                            label: 'Tiếp tục',
                            onTap: () => setState(() => _step = 2),
                          ),
                        ),
                      ],
                    ),
                  ] else ...<Widget>[
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: StudyFlowPalette.green,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(child: Text('Xác nhận học kỳ', style: Theme.of(context).textTheme.headlineSmall)),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Kiểm tra thông tin trước khi xác nhận',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 22),
                    StudyFlowSurfaceCard(
                      color: const Color(0xFFF7F4FF),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const StudyFlowIconBadge(
                                icon: Icons.calendar_month_rounded,
                                backgroundColor: StudyFlowPalette.blue,
                                size: 44,
                                iconSize: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_nameController.text.trim(), style: Theme.of(context).textTheme.titleLarge)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _SummaryRow(label: 'Ngày bắt đầu', value: DateTimeUtils.formatSlashDate(_startDate)),
                          const SizedBox(height: 14),
                          _SummaryRow(label: 'Ngày kết thúc', value: DateTimeUtils.formatSlashDate(_endDate)),
                          const SizedBox(height: 14),
                          _SummaryRow(label: 'Tổng số tuần', value: '${_endDate.difference(_startDate).inDays ~/ 7} tuần'),
                          const SizedBox(height: 14),
                          _SummaryRow(label: 'Tổng số ngày', value: '${_endDate.difference(_startDate).inDays} ngày'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    StudyFlowGradientButton(
                      label: 'Thêm môn học',
                      onTap: _saveSemester,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.title,
    required this.day,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final String day;
  final String month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return StudyFlowSurfaceCard(
      color: const Color(0xFFF6F7FB),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              StudyFlowCircleIconButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(day, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 34)),
                    Text(month, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              StudyFlowCircleIconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: StudyFlowPalette.blue)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
