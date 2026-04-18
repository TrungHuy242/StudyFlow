import 'package:flutter_test/flutter_test.dart';

import 'package:week7_3/app.dart';

void main() {
  testWidgets('app boots into the subjects screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StudySubjectsApp());

    expect(find.text('Môn học'), findsOneWidget);
    expect(find.text('UX/UI Design'), findsOneWidget);
    expect(find.text('Tìm kiếm môn học...'), findsOneWidget);
  });
}
