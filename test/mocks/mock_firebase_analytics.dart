import 'package:firebase_analytics/firebase_analytics.dart';

/// A mock implementation of FirebaseAnalytics for testing
class MockFirebaseAnalytics implements FirebaseAnalytics {
  final List<Map<String, dynamic>> searchLogs = [];
  final List<Map<String, dynamic>> allEvents = [];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    allEvents.add({
      'name': name,
      'parameters': parameters,
      'timestamp': DateTime.now(),
    });
  }

  @override
  Future<void> logSearch({
    required String searchTerm,
    String? origin,
    String? destination,
    String? startDate,
    String? endDate,
    String? travelClass,
    int? numberOfPassengers,
    int? numberOfRooms,
    int? numberOfNights,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    searchLogs.add({
      'searchTerm': searchTerm,
      'origin': origin,
      'destination': destination,
      'parameters': parameters,
      'timestamp': DateTime.now(),
    });
    await logEvent(
      name: 'search',
      parameters: {
        'search_term': searchTerm,
        if (origin != null) 'origin': origin,
        if (destination != null) 'destination': destination,
        if (parameters != null) ...parameters,
      },
    );
  }

  // Implementing required methods with minimal mock behavior
  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setCurrentScreen({
    String? screenName,
    String? screenClassOverride,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> setUserId({
    String? id,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) async {}

  // Add other required methods with minimal implementations as needed

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock helper for testing without actual Firebase dependencies
MockFirebaseAnalytics getMockAnalytics() {
  return MockFirebaseAnalytics();
}
