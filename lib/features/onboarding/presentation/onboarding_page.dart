import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../auth/application/app_session_controller.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  static const List<_SlideData> _slides = <_SlideData>[
    _SlideData(
      titleTop: 'Chào mừng đến với',
      titleBottom: 'StudyFlow',
      lines: <String>[
        'Ứng dụng quản lý học tập thông minh',
        'giúp bạn theo dõi lịch học,',
        'deadline và tiến độ ôn tập',
      ],
      primaryIcon: Icons.menu_book_rounded,
      accentIcon: Icons.auto_awesome_outlined,
      backgroundGradient: StudyFlowPalette.onboardingBlueGradient,
      buttonGradient: StudyFlowPalette.primaryButtonGradient,
      ringColor: Color(0xFFDCEBFF),
      centerColor: Color(0xFFB2D3FF),
      accentColor: StudyFlowPalette.blue,
      buttonLabel: 'Tiếp tục',
    ),
    _SlideData(
      titleTop: 'Quản lý lịch học',
      titleBottom: 'thông minh',
      lines: <String>[
        'Xem lịch học theo ngày, tuần,',
        'tháng. Nhận thông báo nhắc nhở',
        'trước mỗi buổi học',
      ],
      primaryIcon: Icons.calendar_month_rounded,
      accentIcon: Icons.notifications_none_rounded,
      backgroundGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFFDF8FF), Colors.white],
      ),
      buttonGradient: StudyFlowPalette.purpleButtonGradient,
      ringColor: Color(0xFFF0DFFF),
      centerColor: Color(0xFFDCBEFF),
      accentColor: StudyFlowPalette.purple,
      buttonLabel: 'Tiếp tục',
    ),
    _SlideData(
      titleTop: 'Theo dõi tiến độ học',
      titleBottom: 'tập',
      lines: <String>[
        'Xem biểu đồ thống kê, theo dõi',
        'chuỗi ngày học liên tục và đạt được',
        'các thành tựu',
      ],
      primaryIcon: Icons.show_chart_rounded,
      accentIcon: Icons.emoji_events_outlined,
      backgroundGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFF5FFF8), Colors.white],
      ),
      buttonGradient: StudyFlowPalette.greenButtonGradient,
      ringColor: Color(0xFFD8F6E4),
      centerColor: Color(0xFFA6EAC1),
      accentColor: StudyFlowPalette.green,
      buttonLabel: 'Bắt đầu ngay',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<AppSessionController>().completeOnboarding();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  Future<void> _next() async {
    if (_pageIndex == _slides.length - 1) {
      await _finish();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _SlideData slide = _slides[_pageIndex];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(gradient: slide.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Bỏ qua'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (int index) {
                    setState(() {
                      _pageIndex = index;
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return _OnboardingSlideView(slide: _slides[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 18),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(_slides.length, (int index) {
                        final bool active = index == _pageIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: active ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: active ? slide.accentColor : StudyFlowPalette.border,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),
                    StudyFlowGradientButton(
                      label: slide.buttonLabel,
                      gradient: slide.buttonGradient,
                      onTap: _next,
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

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({required this.slide});

  final _SlideData slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 16),
          Expanded(
            flex: 5,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: slide.ringColor,
                    ),
                  ),
                  Container(
                    width: 216,
                    height: 216,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: slide.ringColor.withValues(alpha: 0.72),
                    ),
                  ),
                  Container(
                    width: 152,
                    height: 152,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: slide.centerColor,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: slide.centerColor.withValues(alpha: 0.35),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      slide.primaryIcon,
                      color: Colors.white,
                      size: 68,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 20,
                    child: _AccentBubble(
                      icon: slide.accentIcon,
                      color: slide.accentColor,
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 4,
                    child: _AccentBubble(
                      icon: Icons.bolt_rounded,
                      color: slide.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                Text(
                  slide.titleTop,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: StudyFlowPalette.textPrimary,
                    height: 1.2,
                  ),
                ),
                Text(
                  slide.titleBottom,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: StudyFlowPalette.blue,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 18),
                ...slide.lines.map(
                  (String line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      line,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: StudyFlowPalette.textSecondary,
                        height: 1.5,
                      ),
                    ),
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

class _AccentBubble extends StatelessWidget {
  const _AccentBubble({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.titleTop,
    required this.titleBottom,
    required this.lines,
    required this.primaryIcon,
    required this.accentIcon,
    required this.backgroundGradient,
    required this.buttonGradient,
    required this.ringColor,
    required this.centerColor,
    required this.accentColor,
    required this.buttonLabel,
  });

  final String titleTop;
  final String titleBottom;
  final List<String> lines;
  final IconData primaryIcon;
  final IconData accentIcon;
  final Gradient backgroundGradient;
  final Gradient buttonGradient;
  final Color ringColor;
  final Color centerColor;
  final Color accentColor;
  final String buttonLabel;
}
