/// Test-specific interfaces to avoid sealed class issues
abstract class ITestDocumentSnapshot {
  bool get exists;
  Map<String, dynamic>? data();
}

abstract class ITestFirestoreService {
  Future<ITestDocumentSnapshot> getDocument(String collection, String docId);
  Future<void> setDocument(
      String collection, String docId, Map<String, dynamic> data,
      {bool merge = false});
  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data);
}
