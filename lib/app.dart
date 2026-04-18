import 'package:flutter/material.dart';

import 'screens/subjects_screen.dart';
import 'state/subject_controller.dart';
import 'theme/app_theme.dart';

class StudySubjectsApp extends StatefulWidget {
  const StudySubjectsApp({super.key});

  @override
  State<StudySubjectsApp> createState() => _StudySubjectsAppState();
}

class _StudySubjectsAppState extends State<StudySubjectsApp> {
  late final SubjectController _subjectController;

  @override
  void initState() {
    super.initState();
    _subjectController = SubjectController.seeded();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subjects Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: SubjectsScreen(controller: _subjectController),
    );
  }
}
