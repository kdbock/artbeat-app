import 'package:permission_handler/permission_handler.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Streamlined permission service specifically for messaging features
class MessagingPermissionService {
  static final MessagingPermissionService _instance =
      MessagingPermissionService._internal();
  factory MessagingPermissionService() => _instance;
  MessagingPermissionService._internal();

  /// Check if microphone permission is granted (no additional requests)
  Future<bool> hasMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      AppLogger.info('Microphone permission status: $status');
      return status.isGranted;
    } catch (e) {
      AppLogger.error('❌ Error checking microphone permission: $e');
      return false;
    }
  }

  /// Request microphone permission with user-friendly handling
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;

      if (status.isGranted) {
        AppLogger.info('✅ Microphone permission already granted');
        return true;
      }

      if (status.isPermanentlyDenied) {
        AppLogger.warning(
          '⚠️ Microphone permission permanently denied - opening settings',
        );
        await openAppSettings();
        return false;
      }

      // This should rarely happen since permissions are requested at app startup
      AppLogger.info('Requesting microphone permission for voice recording...');
      final result = await Permission.microphone.request();

      if (result.isGranted) {
        AppLogger.info('✅ Microphone permission granted');
        return true;
      } else if (result.isPermanentlyDenied) {
        AppLogger.warning('⚠️ Microphone permission permanently denied');
        return false;
      } else {
        AppLogger.warning('❌ Microphone permission denied: $result');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Error requesting microphone permission: $e');
      return false;
    }
  }

  /// Get user-friendly permission message
  String getPermissionMessage() {
    return 'Microphone access is needed to record voice messages. Please enable it in your device settings.';
  }
}
