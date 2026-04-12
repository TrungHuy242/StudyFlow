import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  static final DateFormat _dbDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dbDateTimeFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
  static final DateFormat _friendlyDateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _friendlyDateTimeFormat = DateFormat('dd MMM, HH:mm');
  static final DateFormat _monthDayFormat = DateFormat('dd MMM');
  static final DateFormat _weekdayDateFormat = DateFormat('EEE, dd MMM');
  static const List<String> _viWeekdays = <String>[
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];

  static String toDbDate(DateTime value) => _dbDateFormat.format(value);

  static DateTime fromDbDate(String value) => _dbDateFormat.parse(value);

  static String toDbDateTime(DateTime value) => _dbDateTimeFormat.format(value);

  static DateTime fromDbDateTime(String value) => _dbDateTimeFormat.parse(value);

  static String formatDate(DateTime value) => _friendlyDateFormat.format(value);

  static String formatShortDate(DateTime value) => _monthDayFormat.format(value);

  static String formatWeekdayDate(DateTime value) => _weekdayDateFormat.format(value);

  static String formatDateTime(DateTime value) => _friendlyDateTimeFormat.format(value);

  static String formatSlashDate(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String formatVietnameseWeekday(DateTime value) {
    return _viWeekdays[value.weekday - 1];
  }

  static String formatVietnameseLongDate(DateTime value) {
    return '${formatVietnameseWeekday(value)}, ${value.day} tháng ${value.month}';
  }

  static String formatTimeOfDay(TimeOfDay value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static TimeOfDay parseTimeOfDay(String value) {
    final List<String> parts = value.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static DateTime mergeDateAndTime(DateTime date, String? time) {
    if (time == null || time.isEmpty) {
      return DateTime(date.year, date.month, date.day);
    }
    final TimeOfDay parsedTime = parseTimeOfDay(time);
    return DateTime(
      date.year,
      date.month,
      date.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }

  static int daysUntil(DateTime target) {
    final DateTime now = DateTime.now();
    final DateTime current = DateTime(now.year, now.month, now.day);
    final DateTime normalizedTarget = DateTime(target.year, target.month, target.day);
    return normalizedTarget.difference(current).inDays;
  }
}
