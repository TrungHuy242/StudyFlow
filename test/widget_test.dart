import 'package:assignments_deadlines_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows deadline dashboard', (tester) async {
    await tester.pumpWidget(const AssignmentsDeadlinesApp());

    expect(find.text('Deadline'), findsOneWidget);
    expect(find.text('6 deadline chưa hoàn thành'), findsOneWidget);
    expect(find.text('Lab Report 3'), findsOneWidget);
    expect(find.text('Sắp tới'), findsOneWidget);
  });
}
