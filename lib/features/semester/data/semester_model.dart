import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/database_value_utils.dart';

class SemesterModel {
  const SemesterModel({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  String get dateRangeLabel =>
      '${DateTimeUtils.formatDate(startDate)} - ${DateTimeUtils.formatDate(endDate)}';

  SemesterModel copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return SemesterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'start_date': DateTimeUtils.toDbDate(startDate),
      'end_date': DateTimeUtils.toDbDate(endDate),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory SemesterModel.fromMap(Map<String, Object?> map) {
    return SemesterModel(
      id: DatabaseValueUtils.asNullableInt(map['id']),
      name: map['name'] as String? ?? '',
      startDate: DateTimeUtils.fromDbDate(map['start_date'] as String),
      endDate: DateTimeUtils.fromDbDate(map['end_date'] as String),
      isActive: DatabaseValueUtils.asBool(map['is_active']),
    );
  }
}
