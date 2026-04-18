import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/subject.dart';

class SubjectController extends ChangeNotifier {
  SubjectController({List<Subject> initialSubjects = const []})
    : _subjects = List<Subject>.of(initialSubjects);

  factory SubjectController.seeded() {
    return SubjectController(
      initialSubjects: const [
        Subject(
          id: 'ux-ui-design',
          name: 'UX/UI Design',
          code: 'CS401',
          credits: 3,
          teacher: 'Th.S Nguyễn Văn A',
          day: 'Thứ 2',
          time: '7:00 - 9:30',
          room: 'A301',
          progress: 0.65,
          color: Color(0xFF6366F1),
          description:
              'Môn học cung cấp kiến thức nền tảng về thiết kế trải nghiệm người dùng và giao diện người dùng. Sinh viên sẽ học cách nghiên cứu người dùng, tạo persona, thiết kế wireframe, prototype và đánh giá tính khả dụng của sản phẩm số.',
        ),
        Subject(
          id: 'web-development',
          name: 'Web Development',
          code: 'CS402',
          credits: 4,
          teacher: 'Th.S Trần Minh B',
          day: 'Thứ 3',
          time: '9:45 - 12:15',
          room: 'B202',
          progress: 0.45,
          color: Color(0xFF22C55E),
          description:
              'Môn học hướng dẫn xây dựng ứng dụng web hiện đại, bao gồm HTML, CSS, JavaScript, quản lý trạng thái và triển khai giao diện đáp ứng.',
        ),
        Subject(
          id: 'database-systems',
          name: 'Database Systems',
          code: 'CS301',
          credits: 3,
          teacher: 'TS. Lê Thu C',
          day: 'Thứ 4',
          time: '13:00 - 15:30',
          room: 'C105',
          progress: 0.80,
          color: Color(0xFFF59E0B),
          description:
              'Sinh viên học mô hình dữ liệu quan hệ, truy vấn SQL, chuẩn hoá dữ liệu, thiết kế lược đồ và các nguyên tắc tối ưu hoá hệ quản trị cơ sở dữ liệu.',
        ),
        Subject(
          id: 'mobile-programming',
          name: 'Mobile Programming',
          code: 'CS404',
          credits: 3,
          teacher: 'Th.S Phạm Hồng D',
          day: 'Thứ 5',
          time: '15:45 - 18:15',
          room: 'D401',
          progress: 0.55,
          color: Color(0xFF3B82F6),
          description:
              'Môn học tập trung vào thiết kế và phát triển ứng dụng di động, xử lý điều hướng, quản lý dữ liệu cục bộ và trải nghiệm người dùng trên thiết bị nhỏ.',
        ),
        Subject(
          id: 'hci',
          name: 'HCI',
          code: 'CS403',
          credits: 3,
          teacher: 'TS. Nguyễn Hải E',
          day: 'Thứ 6',
          time: '7:00 - 9:30',
          room: 'E302',
          progress: 0.30,
          color: Color(0xFFEC4899),
          description:
              'Môn học nghiên cứu cách con người tương tác với hệ thống máy tính, từ nguyên lý nhận thức đến kiểm thử khả dụng và thiết kế tương tác.',
        ),
      ],
    );
  }

  List<Subject> _subjects;

  UnmodifiableListView<Subject> get subjects =>
      UnmodifiableListView<Subject>(_subjects);

  Subject? subjectById(String id) {
    for (final subject in _subjects) {
      if (subject.id == id) {
        return subject;
      }
    }
    return null;
  }

  void addSubject(Subject subject) {
    _subjects = [
      ..._subjects,
      subject.copyWith(id: _createId(subject.name, subject.code)),
    ];
    notifyListeners();
  }

  void updateSubject(Subject subject) {
    _subjects = [
      for (final current in _subjects)
        if (current.id == subject.id) subject else current,
    ];
    notifyListeners();
  }

  void deleteSubject(String id) {
    _subjects = _subjects.where((subject) => subject.id != id).toList();
    notifyListeners();
  }

  String _createId(String name, String code) {
    final base = '${code.trim()}-${name.trim()}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final fallback = DateTime.now().microsecondsSinceEpoch.toString();
    final seed = base.isEmpty ? fallback : base;
    var candidate = seed;
    var index = 2;
    while (_subjects.any((subject) => subject.id == candidate)) {
      candidate = '$seed-$index';
      index += 1;
    }
    return candidate;
  }
}
