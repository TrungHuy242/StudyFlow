import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../theme/app_theme.dart';

enum SubjectCardAction { edit, delete }

class SubjectCard extends StatelessWidget {
  const SubjectCard({
    required this.subject,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.compact = false,
    super.key,
  });

  final Subject subject;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubjectBadge(subject: subject, size: compact ? 48 : 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        subject.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.text,
                              fontSize: compact ? 15 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (onEdit != null || onDelete != null) _buildMenu(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subject.creditsLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.text,
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: compact ? 10 : 13),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _MetaChip(icon: Icons.schedule_rounded, label: subject.day),
                    _MetaChip(
                      icon: Icons.groups_2_rounded,
                      label: subject.room,
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 13),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tiến độ học tập',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.text,
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${subject.progressPercent} %',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: compact ? 6 : 8,
                    value: subject.progress,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(subject.color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: card,
      ),
    );
  }

  Widget _buildMenu() {
    return PopupMenuButton<SubjectCardAction>(
      tooltip: 'Tùy chọn môn học',
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.subtleText),
      onSelected: (action) {
        switch (action) {
          case SubjectCardAction.edit:
            onEdit?.call();
            break;
          case SubjectCardAction.delete:
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<SubjectCardAction>(
          value: SubjectCardAction.edit,
          child: Text('Sửa môn học'),
        ),
        PopupMenuItem<SubjectCardAction>(
          value: SubjectCardAction.delete,
          child: Text('Xóa môn học'),
        ),
      ],
    );
  }
}

class _SubjectBadge extends StatelessWidget {
  const _SubjectBadge({required this.subject, required this.size});

  final Subject subject;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: subject.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        subject.codePrefix,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontSize: size >= 56 ? 17 : 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.mutedText),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
