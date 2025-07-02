import 'package:flutter/foundation.dart';

class UserService extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> refreshUserData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Add your refresh logic here
      await Future<void>.delayed(const Duration(seconds: 1)); // Simulate network call

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
