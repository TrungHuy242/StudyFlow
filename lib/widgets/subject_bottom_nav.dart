import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SubjectBottomNav extends StatelessWidget {
  const SubjectBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Trang chủ',
                isActive: true,
              ),
              _NavItem(icon: Icons.calendar_month_outlined, label: 'Lịch'),
              _NavItem(icon: Icons.check_box_outlined, label: 'Việc'),
              _NavItem(icon: Icons.bar_chart_rounded, label: 'Thống kê'),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Tôi'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.isActive = false,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primaryDark : AppColors.subtleText;

    return Tooltip(
      message: label,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon ?? icon : icon, color: color, size: 25),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
