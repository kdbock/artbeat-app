/// Interface for Firestore service to enable mocking in tests
abstract class IFirestoreService {
  /// Get a document from a collection
  Future<IDocumentSnapshot> getDocument(String collection, String documentId);
}

/// Interface for Firestore document snapshot to enable mocking in tests
abstract class IDocumentSnapshot {
  /// Whether this document exists
  bool get exists;

  /// Get the document data
  Map<String, dynamic>? data();
}
