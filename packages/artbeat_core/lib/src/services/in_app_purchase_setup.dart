import 'in_app_purchase_manager.dart';
import '../utils/logger.dart';

/// Setup and initialize in-app purchases for the app
class InAppPurchaseSetup {
  factory InAppPurchaseSetup() => _instance;
  InAppPurchaseSetup._internal();
  static final InAppPurchaseSetup _instance = InAppPurchaseSetup._internal();

  final InAppPurchaseManager _purchaseManager = InAppPurchaseManager();
  bool _isInitialized = false;

  /// Initialize in-app purchases
  Future<bool> initialize() async {
    if (_isInitialized) {
      AppLogger.info('In-app purchases already initialized');
      return true;
    }

    try {
      AppLogger.info('🚀 Setting up in-app purchases...');

      final success = await _purchaseManager.initialize();

      if (success) {
        _isInitialized = true;
        AppLogger.info('✅ In-app purchases initialized successfully');

        _setupPurchaseListeners();

        return true;
      } else {
        AppLogger.error('❌ Failed to initialize in-app purchases');
        return false;
      }
    } on Exception catch (e) {
      AppLogger.error('❌ Error initializing in-app purchases: $e');
      return false;
    }
  }

  /// Set up purchase event listeners
  void _setupPurchaseListeners() {
    _purchaseManager.purchaseEventStream.listen(
      (event) {
        switch (event.type) {
          case PurchaseEventType.completed:
            _handlePurchaseCompleted(event);
            break;
          case PurchaseEventType.error:
            _handlePurchaseError(event);
            break;
          case PurchaseEventType.cancelled:
            _handlePurchaseCancelled(event);
            break;
        }
      },
      onError: (Object error) {
        AppLogger.error('Purchase event stream error: $error');
      },
    );
  }

  /// Handle completed purchase
  void _handlePurchaseCompleted(PurchaseEvent event) {
    final purchase = event.purchase!;
    AppLogger.info('🎉 Purchase completed: ${purchase.productId}');
  }

  /// Handle purchase error
  void _handlePurchaseError(PurchaseEvent event) {
    AppLogger.error('❌ Purchase error: ${event.error}');
  }

  /// Handle purchase cancellation
  void _handlePurchaseCancelled(PurchaseEvent event) {
    AppLogger.info('❌ Purchase cancelled: ${event.productId}');
  }

  /// Get the purchase manager instance
  InAppPurchaseManager get purchaseManager => _purchaseManager;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _purchaseManager.dispose();
    _isInitialized = false;
  }
}
