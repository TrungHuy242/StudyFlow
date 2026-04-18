import 'package:flutter/foundation.dart';

class AppRefreshNotifier extends ChangeNotifier {
  int _revision = 0;

  int get revision => _revision;

  void markDirty() {
    _revision++;
    notifyListeners();
  }
}
