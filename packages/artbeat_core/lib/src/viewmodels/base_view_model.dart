import 'package:flutter/foundation.dart';

class DashboardViewModel extends ChangeNotifier {
  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  // Safe update method that checks disposal state
  void safeUpdate(VoidCallback update) {
    if (!_disposed) {
      update();
      notifyListeners();
    }
  }
}
