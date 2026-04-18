import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../state/subject_controller.dart';
import '../theme/app_theme.dart';
import 'subject_form_screen.dart';

class SubjectDetailScreen extends StatelessWidget {
  const SubjectDetailScreen({
    required this.controller,
    required this.subjectId,
    super.key,
  });

  final SubjectController controller;
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final subject = controller.subjectById(subjectId);
        if (subject == null) {
          return const _MissingSubjectScreen();
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: 266,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: subject.color),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 34, 22, 0),
                      child: Row(
                        children: [
                          _HeaderButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Quay lại',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          _HeaderButton(
                            icon: Icons.edit_outlined,
                            tooltip: 'Sửa môn học',
                            onPressed: () => _openEdit(context, subject),
                          ),
                          const SizedBox(width: 12),
                          _HeaderButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Xóa môn học',
                            onPressed: () => _confirmDelete(context, subject),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 34, 22, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.menu_book_outlined,
                              color: AppColors.primary,
                              size: 34,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subject.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subject.creditsLabel,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.82,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 34),
                          children: [
                            _ProgressPanel(subject: subject),
                            const SizedBox(height: 20),
                            _InfoPanel(
                              icon: Icons.groups_2_outlined,
                              label: 'Giảng viên',
                              value: subject.teacher,
                            ),
                            const SizedBox(height: 12),
                            _InfoPanel(
                              icon: Icons.schedule_rounded,
                              label: 'Lịch học',
                              value: '${subject.day}, ${subject.time}',
                            ),
                            const SizedBox(height: 12),
                            _InfoPanel(
                              icon: Icons.location_on_outlined,
                              label: 'Phòng học',
                              value: subject.room,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickActionCard(
                                    icon: Icons.assignment_outlined,
                                    color: const Color(0xFF3B82F6),
                                    title: 'Deadline',
                                    subtitle: 'Thêm mới',
                                    onTap: () => _showFeatureMessage(
                                      context,
                                      'Deadline cho ${subject.name}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _QuickActionCard(
                                    icon: Icons.calendar_month_outlined,
                                    color: const Color(0xFFA855F7),
                                    title: 'Kế hoạch',
                                    subtitle: 'Tạo mới',
                                    onTap: () => _showFeatureMessage(
                                      context,
                                      'Kế hoạch học tập cho ${subject.name}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Mô tả',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              subject.description,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppColors.mutedText,
                                    height: 1.65,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                          ],
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
    );
  }

  void _openEdit(BuildContext context, Subject subject) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SubjectFormScreen(controller: controller, subject: subject),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Subject subject) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa môn học?'),
        content: Text('Bạn có chắc muốn xóa ${subject.name} khỏi danh sách?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }
    controller.deleteSubject(subject.id);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showFeatureMessage(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label sẽ được nối với module Việc/Lịch.')),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 24),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          minimumSize: const Size(42, 42),
        ),
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tiến độ học tập',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${subject.progressPercent} %',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: subject.progress,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(subject.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.mutedText, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingSubjectScreen extends StatelessWidget {
  const _MissingSubjectScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Môn học không tồn tại.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
