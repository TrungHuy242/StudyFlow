class User {
  String name;
  int points;
  int level;

  User({required this.name, this.points = 0, this.level = 1});

  void addPoints(int value) {
    points += value;
    _checkLevelUp();
  }

  void _checkLevelUp() {
    if (points >= level * 100) {
      level++;
      print("🎉 Level up! Bạn đã lên level $level");
    }
  }

  void showInfo() {
    print("👤 $name | ⭐ Points: $points | 🏆 Level: $level");
  }
}

void main() {
  User user = User(name: "Hien");

  user.showInfo();

  user.addPoints(50);
  user.showInfo();

  user.addPoints(60); // sẽ level up
  user.showInfo();
}