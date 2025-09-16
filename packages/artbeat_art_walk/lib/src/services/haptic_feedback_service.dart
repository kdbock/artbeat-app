import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Haptic feedback patterns for different interactions
enum HapticPattern {
  light, // Light vibration for subtle feedback
  medium, // Medium vibration for normal interactions
  heavy, // Heavy vibration for important actions
  success, // Success pattern for achievements
  error, // Error pattern for mistakes
  warning, // Warning pattern for cautions
  navigation, // Navigation pattern for directions
  celebration, // Celebration pattern for milestones
}

/// Service for managing haptic feedback throughout the app
class HapticFeedbackService {
  static HapticFeedbackService? _instance;
  static SharedPreferences? _prefs;

  static const String _hapticsEnabledKey = 'haptics_enabled';
  static const String _hapticsIntensityKey = 'haptics_intensity';

  bool _isInitialized = false;

  HapticFeedbackService._internal();

  static Future<HapticFeedbackService> getInstance() async {
    if (_instance == null) {
      _prefs = await SharedPreferences.getInstance();
      _instance = HapticFeedbackService._internal();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// Check if haptics are enabled
  bool get isHapticsEnabled {
    return _prefs?.getBool(_hapticsEnabledKey) ?? true;
  }

  /// Enable/disable haptics
  Future<void> setHapticsEnabled(bool enabled) async {
    await _prefs?.setBool(_hapticsEnabledKey, enabled);
  }

  /// Get haptics intensity (0.0 to 1.0)
  double get hapticsIntensity {
    return _prefs?.getDouble(_hapticsIntensityKey) ?? 0.7;
  }

  /// Set haptics intensity
  Future<void> setHapticsIntensity(double intensity) async {
    await _prefs?.setDouble(_hapticsIntensityKey, intensity.clamp(0.0, 1.0));
  }

  /// Trigger haptic feedback based on pattern
  Future<void> trigger(HapticPattern pattern) async {
    if (!isHapticsEnabled) return;

    switch (pattern) {
      case HapticPattern.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticPattern.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticPattern.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticPattern.success:
        await HapticFeedback.lightImpact();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.lightImpact();
        break;
      case HapticPattern.error:
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
        break;
      case HapticPattern.warning:
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.lightImpact();
        break;
      case HapticPattern.navigation:
        await HapticFeedback.lightImpact();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await HapticFeedback.lightImpact();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await HapticFeedback.lightImpact();
        break;
      case HapticPattern.celebration:
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.lightImpact();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Contextual haptic feedback methods

  /// Haptic feedback when approaching an art piece (50m)
  Future<void> approachingArtPiece() async {
    await trigger(HapticPattern.light);
  }

  /// Haptic feedback when visiting an art piece
  Future<void> artPieceVisited() async {
    await trigger(HapticPattern.success);
  }

  /// Haptic feedback for navigation turn
  Future<void> navigationTurn() async {
    await trigger(HapticPattern.navigation);
  }

  /// Haptic feedback for walk completion
  Future<void> walkCompleted() async {
    await trigger(HapticPattern.celebration);
  }

  /// Haptic feedback for achievement unlocked
  Future<void> achievementUnlocked() async {
    await trigger(HapticPattern.success);
  }

  /// Haptic feedback for error states
  Future<void> errorOccurred() async {
    await trigger(HapticPattern.error);
  }

  /// Haptic feedback for button interactions
  Future<void> buttonPressed() async {
    await trigger(HapticPattern.light);
  }

  /// Haptic feedback for map marker interactions
  Future<void> markerTapped() async {
    await trigger(HapticPattern.medium);
  }

  /// Haptic feedback for progress updates
  Future<void> progressUpdated() async {
    await trigger(HapticPattern.light);
  }

  /// Haptic feedback for location permission request
  Future<void> locationPermissionRequested() async {
    await trigger(HapticPattern.warning);
  }

  /// Haptic feedback for offline mode activation
  Future<void> offlineModeActivated() async {
    await trigger(HapticPattern.medium);
  }

  /// Haptic feedback for connectivity restored
  Future<void> connectivityRestored() async {
    await trigger(HapticPattern.success);
  }
}
