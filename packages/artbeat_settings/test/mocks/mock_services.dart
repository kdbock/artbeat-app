import 'package:mockito/mockito.dart';
import 'package:artbeat_settings/src/interfaces/i_auth_service.dart';
import 'package:artbeat_settings/src/interfaces/i_firestore_service.dart';

class MockIAuthService extends Mock implements IAuthService {}

class MockIFirestoreService extends Mock implements IFirestoreService {}

class MockUser extends Mock implements IUser {
  final String _uid;

  MockUser({required String uid}) : _uid = uid;

  @override
  String get uid => _uid;
}

class MockDocumentSnapshot extends Mock implements IDocumentSnapshot {}
