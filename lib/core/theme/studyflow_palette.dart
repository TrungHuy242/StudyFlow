import 'package:flutter/material.dart';

class StudyFlowPalette {
  static const Color background = Color(0xFFF7F9FD);
  static const Color backgroundWarm = Color(0xFFFFFBF1);
  static const Color surface = Colors.white;
  static const Color surfaceSoft = Color(0xFFF3F6FB);
  static const Color surfaceMuted = Color(0xFFEFF3F9);
  static const Color border = Color(0xFFE3EAF5);
  static const Color divider = Color(0xFFDCE4F0);

  static const Color textPrimary = Color(0xFF1B2740);
  static const Color textSecondary = Color(0xFF6F7E97);
  static const Color textMuted = Color(0xFF97A6BF);

  static const Color blue = Color(0xFF2F63F6);
  static const Color blueSoft = Color(0xFF97BAFF);
  static const Color indigo = Color(0xFF6F62FF);
  static const Color purple = Color(0xFFA153FF);
  static const Color green = Color(0xFF2ECB6F);
  static const Color orange = Color(0xFFFFA31A);
  static const Color coral = Color(0xFFFF6B57);
  static const Color red = Color(0xFFFF5A44);

  static const double radiusXs = 12;
  static const double radiusSm = 16;
  static const double radiusMd = 20;
  static const double radiusLg = 24;
  static const double radiusXl = 28;

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF3C73FF),
      Color(0xFF234FD7),
    ],
  );

  static const LinearGradient onboardingBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFE8F0FF),
      Color(0xFFF0F4FF),
      Colors.white,
    ],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[
      Color(0xFF91B8FF),
      blue,
    ],
  );

  static const LinearGradient purpleButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[
      Color(0xFFB875FF),
      purple,
    ],
  );

  static const LinearGradient greenButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[
      Color(0xFF63D892),
      green,
    ],
  );

  static List<BoxShadow> get softShadow => const <BoxShadow>[
        BoxShadow(
          color: Color(0x120F2A62),
          blurRadius: 30,
          offset: Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get cardShadow => const <BoxShadow>[
        BoxShadow(
          color: Color(0x0D0F2A62),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ];
}
