import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/studyflow_palette.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) {
      return;
    }
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: StudyFlowPalette.splashGradient),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Positioned(
                left: -54,
                top: 286,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                right: 24,
                top: 198,
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: StudyFlowPalette.blue,
                        size: 52,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 34,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quản lý học tập thông minh',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 52,
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List<Widget>.generate(
                        3,
                        (int index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: index == 1 ? 0.95 : 0.38),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Đang khởi động...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SDG 4: Quality Education',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                            fontSize: 13,
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
