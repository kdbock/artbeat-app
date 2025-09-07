import 'package:flutter/foundation.dart';
import 'image_management_service.dart';

/// Service to handle app initialization tasks
class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize all core services
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ AppInitializationService already initialized');
      return;
    }

    debugPrint('🚀 Initializing ARTbeat Core Services...');

    try {
      // Initialize image management service
      await ImageManagementService().initialize();

      // Add other service initializations here

      _isInitialized = true;
      debugPrint('✅ ARTbeat Core Services initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize ARTbeat Core Services: $e');
      rethrow;
    }
  }

  /// Reset initialization state (for testing)
  void reset() {
    _isInitialized = false;
    debugPrint('🔄 AppInitializationService reset');
  }
}
