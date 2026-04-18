import 'package:flutter/material.dart';

enum DeadlinePriority { low, normal, urgent }

class DeadlineItem {
  const DeadlineItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.category,
    required this.dueDate,
    required this.dueTime,
    required this.priority,
    required this.progress,
    required this.color,
    this.description = '',
    this.completed = false,
  });

  final String id;
  final String title;
  final String subject;
  final String category;
  final DateTime dueDate;
  final TimeOfDay dueTime;
  final DeadlinePriority priority;
  final int progress;
  final Color color;
  final String description;
  final bool completed;

  bool isOverdue(DateTime now) {
    return !completed && dueDateTime.isBefore(now);
  }

  bool isDueToday(DateTime now) {
    return !completed &&
        dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  DateTime get dueDateTime {
    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      dueTime.hour,
      dueTime.minute,
    );
  }

  String get priorityLabel {
    return switch (priority) {
      DeadlinePriority.low => 'Thấp',
      DeadlinePriority.normal => 'Bình thường',
      DeadlinePriority.urgent => 'Khẩn cấp',
    };
  }

  String get dueDateLabel {
    return '${dueDate.year}-${_two(dueDate.month)}-${_two(dueDate.day)}';
  }

  String dueTimeLabel() => '${_two(dueTime.hour)}:${_two(dueTime.minute)}';

  int daysLeft(DateTime now) {
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return due.difference(today).inDays;
  }

  String badgeText(DateTime now) {
    if (completed) {
      return 'Xong';
    }

    final days = daysLeft(now);
    if (days < 0) {
      return 'Quá hạn';
    }
    if (days == 0) {
      return 'Hôm nay';
    }
    return '$days ngày';
  }

  DeadlineItem copyWith({
    String? id,
    String? title,
    String? subject,
    String? category,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    DeadlinePriority? priority,
    int? progress,
    Color? color,
    String? description,
    bool? completed,
  }) {
    return DeadlineItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      color: color ?? this.color,
      description: description ?? this.description,
      completed: completed ?? this.completed,
    );
  }
}

String _two(int value) => value.toString().padLeft(2, '0');
