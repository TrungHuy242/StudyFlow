import 'package:flutter/material.dart';

import '../models/deadline_item.dart';

final demoNow = DateTime(2026, 4, 9, 9, 41);

List<DeadlineItem> createSampleDeadlines() {
  return <DeadlineItem>[
    DeadlineItem(
      id: 'lab-report-3',
      title: 'Lab Report 3',
      subject: 'Database Systems',
      category: 'Lab',
      dueDate: DateTime(2026, 4, 8),
      dueTime: const TimeOfDay(hour: 23, minute: 59),
      priority: DeadlinePriority.urgent,
      progress: 0,
      color: const Color(0xFFEF4444),
      description: 'Báo cáo lab số 3 về truy vấn SQL và chuẩn hóa dữ liệu.',
    ),
    DeadlineItem(
      id: 'assignment-ux',
      title: 'Assignment 1 - UX Research',
      subject: 'UX/UI Design',
      category: 'Research',
      dueDate: DateTime(2026, 4, 11),
      dueTime: const TimeOfDay(hour: 23, minute: 59),
      priority: DeadlinePriority.normal,
      progress: 60,
      color: const Color(0xFF6366F1),
      description: 'Phân tích persona, journey map và insight người dùng.',
    ),
    DeadlineItem(
      id: 'quiz-html-css',
      title: 'Quiz - HTML/CSS',
      subject: 'Web Development',
      category: 'Quiz',
      dueDate: DateTime(2026, 4, 9),
      dueTime: const TimeOfDay(hour: 10, minute: 0),
      priority: DeadlinePriority.normal,
      progress: 80,
      color: const Color(0xFF22C55E),
      description: 'Hoàn thành quiz ngắn về semantic HTML và CSS layout.',
    ),
    DeadlineItem(
      id: 'project-database',
      title: 'Project - Database',
      subject: 'Database Systems',
      category: 'Design',
      dueDate: DateTime(2026, 4, 14),
      dueTime: const TimeOfDay(hour: 23, minute: 59),
      priority: DeadlinePriority.low,
      progress: 40,
      color: const Color(0xFFF59E0B),
      description: 'Thiết kế ERD, schema và kế hoạch triển khai database.',
    ),
    DeadlineItem(
      id: 'essay-technical',
      title: 'Essay - Technical Writing',
      subject: 'English for IT',
      category: 'Writing',
      dueDate: DateTime(2026, 4, 17),
      dueTime: const TimeOfDay(hour: 23, minute: 59),
      priority: DeadlinePriority.low,
      progress: 20,
      color: const Color(0xFFEC4899),
      description: 'Viết essay ngắn về một chủ đề công nghệ đang học.',
    ),
    DeadlineItem(
      id: 'midterm-review',
      title: 'Midterm Review',
      subject: 'HCI',
      category: 'Review',
      dueDate: DateTime(2026, 4, 19),
      dueTime: const TimeOfDay(hour: 8, minute: 0),
      priority: DeadlinePriority.low,
      progress: 10,
      color: const Color(0xFF06B6D4),
      description: 'Ôn tập các khái niệm tương tác người máy cho midterm.',
    ),
  ];
}
