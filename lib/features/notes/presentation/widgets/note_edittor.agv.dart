import 'dart:async';

class Reminder {
  String title;
  DateTime time;

  Reminder({required this.title, required this.time});

  void schedule() {
    final now = DateTime.now();
    final difference = time.difference(now);

    if (difference.isNegative) {
      print("⛔ Thời gian đã qua!");
      return;
    }

    Timer(difference, () {
      print("🔔 Nhắc nhở: $title lúc ${time.toString()}");
    });

    print("✅ Đã đặt nhắc nhở: $title");
  }
}

void main() {
  final reminder = Reminder(
    title: "Học Git và Codex",
    time: DateTime.now().add(Duration(seconds: 10)),
  );

  reminder.schedule();
}