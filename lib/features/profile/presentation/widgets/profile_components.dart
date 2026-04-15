import 'package:flutter/material.dart';

import '../../../../core/theme/studyflow_palette.dart';
import '../../../../shared/widgets/studyflow_components.dart';
import '../../data/user_settings_model.dart';

class ProfileDetailScaffold extends StatelessWidget {
  const ProfileDetailScaffold({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 28),
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: padding,
          children: <Widget>[
            Row(
              children: <Widget>[
                StudyFlowCircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  size: 42,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: trailing ?? const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class ProfileAvatarBadge extends StatelessWidget {
  const ProfileAvatarBadge({
    super.key,
    required this.name,
    this.size = 78,
  });

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String initials = profileInitials(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF93C5FD),
            Color(0xFF2563EB),
          ],
        ),
        boxShadow: StudyFlowPalette.cardShadow,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class ProfileInfoShell extends StatelessWidget {
  const ProfileInfoShell({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: child,
        ),
      ],
    );
  }
}

class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration.collapsed(hintText: hintText),
    );
  }
}

class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        danger ? const Color(0xFFEF4444) : const Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF475569)),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  danger
                      ? Icons.logout_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: danger
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF94A3B8),
                ),
          ],
        ),
      ),
    );
  }
}

class ProfileToggle extends StatelessWidget {
  const ProfileToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool interactive = enabled && onChanged != null;
    final Color backgroundColor;
    if (!interactive) {
      backgroundColor =
          value ? const Color(0xFF86EFAC) : const Color(0xFFD4D4D8);
    } else {
      backgroundColor =
          value ? const Color(0xFF34D399) : const Color(0xFFD4D4D8);
    }

    return GestureDetector(
      onTap: interactive ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileActionButtons extends StatelessWidget {
  const ProfileActionButtons({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.cancelLabel = 'Hủy',
    this.onCancel,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String cancelLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextButton(
            onPressed: onCancel ?? () => Navigator.of(context).maybePop(),
            child: Text(
              cancelLabel,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  Color(0xFF93C5FD),
                  Color(0xFF2563EB),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TextButton(
              onPressed: onPrimary,
              child: Text(
                primaryLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ThemeOptionCard extends StatelessWidget {
  const ThemeOptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        selected ? const Color(0xFFE8F0FF) : Colors.white;
    final Color borderColor =
        selected ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0);
    final Color textColor = selected
        ? const Color(0xFF2563EB)
        : enabled
            ? const Color(0xFF475569)
            : const Color(0xFF94A3B8);

    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String profileInitials(String name) {
  final List<String> parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'SV';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

String profileStudentId(UserSettingsModel settings) {
  final String studentCode = (settings.studentCode ?? '').trim();
  if (studentCode.isNotEmpty) {
    return studentCode;
  }
  return 'B21DCCN123';
}

String profileJoinDate(UserSettingsModel settings) {
  final DateTime? joinedAt = settings.joinedAt;
  if (joinedAt != null) {
    final String year = joinedAt.year.toString().padLeft(4, '0');
    final String month = joinedAt.month.toString().padLeft(2, '0');
    final String day = joinedAt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
  return '2026-04-14';
}
