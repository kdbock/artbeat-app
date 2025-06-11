import 'package:flutter/material.dart';
import 'artbeat_theme.dart';

class ArtbeatThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeData get currentTheme =>
      _isDarkMode ? ArtbeatTheme.darkTheme : ArtbeatTheme.lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}
