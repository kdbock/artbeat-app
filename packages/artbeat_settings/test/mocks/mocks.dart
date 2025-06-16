import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:artbeat_settings/src/services/testable_settings_service.dart';

// Mock classes for testing
class MockIAuthService extends Mock implements IAuthService {}

class MockIFirestoreService extends Mock implements IFirestoreService {}

class MockUser extends Mock implements User {
  @override
  final String uid;

  MockUser({required this.uid});
}

/// Document snapshot interface for testing
abstract class ITestDocumentSnapshot {
  bool get exists;
  Map<String, dynamic>? data();
}

class MockDocumentSnapshot extends Mock implements ITestDocumentSnapshot {}
