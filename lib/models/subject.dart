import 'package:flutter/material.dart';

@immutable
class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.credits,
    required this.teacher,
    required this.day,
    required this.time,
    required this.room,
    required this.progress,
    required this.color,
    required this.description,
  });

  final String id;
  final String name;
  final String code;
  final int credits;
  final String teacher;
  final String day;
  final String time;
  final String room;
  final double progress;
  final Color color;
  final String description;

  String get codePrefix {
    final letters = code.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.isEmpty) {
      return name
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .take(2)
          .map((part) => part[0].toUpperCase())
          .join();
    }
    return letters.length > 2
        ? letters.substring(0, 2).toUpperCase()
        : letters.toUpperCase();
  }

  String get creditsLabel => '$code • $credits tín chỉ';

  int get progressPercent => (progress * 100).round();

  Subject copyWith({
    String? id,
    String? name,
    String? code,
    int? credits,
    String? teacher,
    String? day,
    String? time,
    String? room,
    double? progress,
    Color? color,
    String? description,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      credits: credits ?? this.credits,
      teacher: teacher ?? this.teacher,
      day: day ?? this.day,
      time: time ?? this.time,
      room: room ?? this.room,
      progress: progress ?? this.progress,
      color: color ?? this.color,
      description: description ?? this.description,
    );
  }
}
