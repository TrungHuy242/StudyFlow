import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_calendar_app/main.dart';

void main() {
  testWidgets('shows the schedule calendar home screen', (tester) async {
    await tester.pumpWidget(const ScheduleCalendarApp());

    expect(find.text('Lịch học'), findsOneWidget);
    expect(find.text('Ngày'), findsOneWidget);
    expect(find.text('Tuần'), findsOneWidget);
    expect(find.text('Tháng'), findsOneWidget);
    expect(find.text('UX/UI Design'), findsOneWidget);
  });
}
