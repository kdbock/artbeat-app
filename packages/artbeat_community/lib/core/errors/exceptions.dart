class StudioNotFoundException implements Exception {
  final String message;

  StudioNotFoundException([this.message = 'Studio not found']);

  @override
  String toString() => 'StudioNotFoundException: $message';
}

class FirestoreOperationException implements Exception {
  final String message;

  FirestoreOperationException([this.message = 'Firestore operation failed']);

  @override
  String toString() => 'FirestoreOperationException: $message';
}

class InvalidStudioDataException implements Exception {
  final String message;

  InvalidStudioDataException([this.message = 'Invalid studio data']);

  @override
  String toString() => 'InvalidStudioDataException: $message';
}
