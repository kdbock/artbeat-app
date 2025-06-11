import 'package:shared_preferences/shared_preferences.dart';

/// Sets up mock SharedPreferences for testing
Future<void> setupMockSharedPreferences() async {
  SharedPreferences.setMockInitialValues({});
}
