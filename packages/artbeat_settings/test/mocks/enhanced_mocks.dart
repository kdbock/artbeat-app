import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_settings/src/services/testable_settings_service.dart';
import 'package:artbeat_settings/src/interfaces/test_interfaces.dart';

/// Mock for IAuthService
class MockAuthService implements IAuthService {
  final String _userId;

  MockAuthService(this._userId);

  @override
  User? get currentUser => MockUser(_userId);

  @override
  Stream<User?> get authStateChanges => Stream.value(MockUser(_userId));
}

/// Mock for User
class MockUser implements User {
  final String _uid;

  MockUser(this._uid);

  @override
  String get uid => _uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock for IFirestoreService
class MockFirestoreService implements IFirestoreService {
  final Map<String, Map<String, dynamic>> _data = {};

  void addMockDocument(
      String collection, String docId, Map<String, dynamic> data) {
    if (!_data.containsKey(collection)) {
      _data[collection] = {};
    }
    _data[collection]![docId] = data;
  }

  @override
  Future<ITestDocumentSnapshot> getDocument(
      String collection, String docId) async {
    if (_data.containsKey(collection) &&
        _data[collection]!.containsKey(docId)) {
      return MockDocumentSnapshot(
        exists: true,
        data: _data[collection]![docId]!,
      );
    }
    return MockDocumentSnapshot(exists: false);
  }

  @override
  Future<void> setDocument(
      String collection, String docId, Map<String, dynamic> data,
      {bool merge = false}) async {
    if (!_data.containsKey(collection)) {
      _data[collection] = {};
    }

    if (merge && _data[collection]!.containsKey(docId)) {
      _data[collection]![docId]!.addAll(data);
    } else {
      _data[collection]![docId] = data;
    }
  }

  @override
  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    if (!_data.containsKey(collection)) {
      _data[collection] = {};
    }

    if (_data[collection]!.containsKey(docId)) {
      _data[collection]![docId]!.addAll(data);
    } else {
      _data[collection]![docId] = data;
    }
  }
}

/// Mock for document snapshots in tests
class MockDocumentSnapshot implements ITestDocumentSnapshot {
  final bool _exists;
  final Map<String, dynamic> _data;

  MockDocumentSnapshot({required bool exists, Map<String, dynamic>? data})
      : _exists = exists,
        _data = data ?? {};

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _exists ? _data : null;
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
