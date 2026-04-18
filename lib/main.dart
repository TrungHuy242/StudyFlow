import 'package:flutter/material.dart';

import 'screens/schedule_shell_page.dart';

void main() {
  runApp(const ScheduleCalendarApp());
}

class ScheduleCalendarApp extends StatelessWidget {
  const ScheduleCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3F6DF6);

    return MaterialApp(
      title: 'Schedule Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8FC),
          foregroundColor: Color(0xFF101828),
          elevation: 0,
          centerTitle: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: const ScheduleShellPage(),
    );
  }
}
