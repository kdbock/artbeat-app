/// Interface for document snapshot functionality required for testing
abstract class ITestDocumentSnapshot {
  /// Whether the document exists in Firebase
  bool get exists;

  /// Get the document data as a Map
  Map<String, dynamic>? data();
}
