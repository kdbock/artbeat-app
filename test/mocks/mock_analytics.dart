/// A simple mock class for tracking search analytics in tests
class MockAnalytics {
  final List<Map<String, dynamic>> searchLogs = [];

  Future<void> logSearch({
    String? searchTerm,
    Map<String, dynamic>? parameters,
  }) async {
    searchLogs.add({
      'searchTerm': searchTerm,
      'parameters': parameters,
      'timestamp': DateTime.now(),
    });
  }
}

/// Mock helper for testing without actual Firebase dependencies
MockAnalytics getMockAnalytics() {
  return MockAnalytics();
}
