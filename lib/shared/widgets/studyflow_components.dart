import 'package:flutter/material.dart';

import '../../core/theme/studyflow_palette.dart';

class StudyFlowIconBadge extends StatelessWidget {
  const StudyFlowIconBadge({
    super.key,
    required this.icon,
    required this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.size = 64,
    this.iconSize = 28,
    this.borderRadius,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;
  final double iconSize;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
      ),
      child: Icon(icon, color: foregroundColor, size: iconSize),
    );
  }
}

class StudyFlowCircleIconButton extends StatelessWidget {
  const StudyFlowCircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor = StudyFlowPalette.surfaceSoft,
    this.foregroundColor = StudyFlowPalette.textSecondary,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 18, color: foregroundColor),
        ),
      ),
    );
  }
}

class StudyFlowGradientButton extends StatelessWidget {
  const StudyFlowGradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient = StudyFlowPalette.primaryButtonGradient,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onTap;
  final Gradient gradient;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(StudyFlowPalette.radiusSm),
          boxShadow: StudyFlowPalette.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(StudyFlowPalette.radiusSm),
            onTap: onTap,
            child: SizedBox(
              height: height,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StudyFlowOutlineButton extends StatelessWidget {
  const StudyFlowOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(height),
        backgroundColor: StudyFlowPalette.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }
}

class StudyFlowInput extends StatelessWidget {
  const StudyFlowInput({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.textInputAction,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(
            label!,
            style: const TextStyle(
              color: StudyFlowPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          validator: validator,
          textInputAction: textInputAction,
          maxLines: obscureText ? 1 : maxLines,
          enabled: enabled,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: StudyFlowPalette.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 18, color: StudyFlowPalette.textMuted),
            suffixIcon: suffixIcon == null
                ? null
                : IconButton(
                    onPressed: onSuffixTap,
                    icon: Icon(
                      suffixIcon,
                      size: 18,
                      color: StudyFlowPalette.textMuted,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class StudyFlowSurfaceCard extends StatelessWidget {
  const StudyFlowSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = StudyFlowPalette.surface,
    this.radius = StudyFlowPalette.radiusMd,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: StudyFlowPalette.border),
        boxShadow: StudyFlowPalette.cardShadow,
      ),
      padding: padding,
      child: child,
    );
  }
}

class StudyFlowProgressBar extends StatelessWidget {
  const StudyFlowProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
    this.backgroundColor = const Color(0xFFE3E9F3),
  });

  final double value;
  final Color color;
  final double height;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          backgroundColor: backgroundColor,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

class StudyFlowBottomNavBar extends StatelessWidget {
  const StudyFlowBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_BottomNavItem> _items = <_BottomNavItem>[
    _BottomNavItem('Trang chủ', Icons.home_outlined, Icons.home_rounded),
    _BottomNavItem('Lịch', Icons.calendar_month_outlined, Icons.calendar_month_rounded),
    _BottomNavItem('Việc', Icons.check_box_outlined, Icons.check_box_rounded),
    _BottomNavItem('Thống kê', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
    _BottomNavItem('Tôi', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: StudyFlowPalette.surface,
        border: Border(top: BorderSide(color: StudyFlowPalette.border)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 18),
      child: Row(
        children: List<Widget>.generate(_items.length, (int index) {
          final _BottomNavItem item = _items[index];
          final bool selected = index == currentIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      selected ? item.selectedIcon : item.icon,
                      size: 20,
                      color: selected ? StudyFlowPalette.blue : StudyFlowPalette.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? StudyFlowPalette.blue : StudyFlowPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
