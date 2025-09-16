import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing capture terms and conditions acceptance
class CaptureTermsService {
  static const String _captureTermsAcceptedKey = 'capture_terms_accepted';

  /// Mark terms as accepted by the user
  static Future<void> markTermsAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_captureTermsAcceptedKey, true);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Check if the user has accepted capture terms
  static Future<bool> hasAcceptedTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_captureTermsAcceptedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Reset terms acceptance (for testing or user logout)
  static Future<void> resetTermsAcceptance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_captureTermsAcceptedKey);
    } catch (e) {
      // Silently fail - not critical
    }
  }
}
