import 'package:flutter/material.dart';

import '../../../../core/theme/studyflow_palette.dart';
import '../../../../shared/widgets/studyflow_components.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.badgeIcon = Icons.auto_stories_rounded,
    this.onBack,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final IconData badgeIcon;
  final VoidCallback? onBack;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (onBack != null) ...<Widget>[
                      StudyFlowCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: onBack,
                      ),
                      const SizedBox(height: 24),
                    ],
                    StudyFlowIconBadge(
                      icon: badgeIcon,
                      backgroundColor: StudyFlowPalette.indigo,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: 22,
                            height: 1.15,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 28),
                    body,
                  ],
                ),
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}
