import 'package:flutter/material.dart';

import 'studyflow_palette.dart';

class AppTheme {
  static ThemeData get light {
    const Color seed = StudyFlowPalette.blue;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      useMaterial3: false,
      scaffoldBackgroundColor: StudyFlowPalette.background,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: StudyFlowPalette.textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: StudyFlowPalette.surfaceSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StudyFlowPalette.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StudyFlowPalette.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StudyFlowPalette.radiusSm),
          borderSide: const BorderSide(color: seed, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        hintStyle: const TextStyle(
          color: StudyFlowPalette.textMuted,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: StudyFlowPalette.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: StudyFlowPalette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudyFlowPalette.radiusMd),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: StudyFlowPalette.blue,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StudyFlowPalette.radiusSm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: StudyFlowPalette.blue,
          side: const BorderSide(color: StudyFlowPalette.blue, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StudyFlowPalette.radiusSm),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      dividerColor: StudyFlowPalette.divider,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: StudyFlowPalette.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: StudyFlowPalette.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: StudyFlowPalette.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: StudyFlowPalette.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: StudyFlowPalette.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.35,
          color: StudyFlowPalette.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.35,
          color: StudyFlowPalette.textSecondary,
        ),
      ),
    );
  }

  static ThemeData get dark {
    const Color seed = StudyFlowPalette.blueSoft;
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: false,
      scaffoldBackgroundColor: const Color(0xFF07111F),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F1B2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: seed, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: const Color(0xFF0F1B2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudyFlowPalette.radiusMd),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StudyFlowPalette.radiusSm),
          ),
        ),
      ),
    );
  }
}
