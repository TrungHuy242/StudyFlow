import 'package:flutter/material.dart';

class SubjectModel {
  const SubjectModel({
    this.id,
    this.semesterId,
    this.semesterName,
    required this.name,
    required this.code,
    required this.color,
    required this.credits,
    required this.teacher,
    required this.room,
    required this.note,
  });

  final int? id;
  final int? semesterId;
  final String? semesterName;
  final String name;
  final String code;
  final String color;
  final int credits;
  final String teacher;
  final String room;
  final String note;

  Color get displayColor => Color(int.parse(color.replaceFirst('#', '0xFF')));

  SubjectModel copyWith({
    int? id,
    int? semesterId,
    String? semesterName,
    String? name,
    String? code,
    String? color,
    int? credits,
    String? teacher,
    String? room,
    String? note,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      semesterName: semesterName ?? this.semesterName,
      name: name ?? this.name,
      code: code ?? this.code,
      color: color ?? this.color,
      credits: credits ?? this.credits,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'semester_id': semesterId,
      'name': name,
      'code': code,
      'color': color,
      'credits': credits,
      'teacher': teacher,
      'room': room,
      'note': note,
    };
  }

  factory SubjectModel.fromMap(Map<String, Object?> map) {
    return SubjectModel(
      id: map['id'] as int?,
      semesterId: map['semester_id'] as int?,
      semesterName: map['semester_name'] as String?,
      name: map['name'] as String? ?? '',
      code: map['code'] as String? ?? '',
      color: map['color'] as String? ?? '#2563EB',
      credits: map['credits'] as int? ?? 3,
      teacher: map['teacher'] as String? ?? '',
      room: map['room'] as String? ?? '',
      note: map['note'] as String? ?? '',
    );
  }
}
