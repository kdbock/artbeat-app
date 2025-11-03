import '../models/capture_model.dart';

/// Abstract interface for capture operations
/// This allows core components to depend on capture functionality
/// without creating circular dependencies
abstract class CaptureServiceInterface {
  /// Get all captures with optional limit
  Future<List<CaptureModel>> getAllCaptures({int limit = 50});

  /// Get captures for a specific user
  Future<List<CaptureModel>> getCapturesForUser(String? userId);

  /// Search captures by query
  Future<List<CaptureModel>> searchCaptures(String query);
}

/// Default implementation that returns empty results
/// This is used when artbeat_capture is not available
class DefaultCaptureService implements CaptureServiceInterface {
  @override
  Future<List<CaptureModel>> getAllCaptures({int limit = 50}) async {
    return [];
  }

  @override
  Future<List<CaptureModel>> getCapturesForUser(String? userId) async {
    return [];
  }

  @override
  Future<List<CaptureModel>> searchCaptures(String query) async {
    return [];
  }
}
