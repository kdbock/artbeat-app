/// Interface for Auth service to enable mocking in tests
abstract class IAuthService {
  /// Get the current user
  IUser? get currentUser;
}

/// Interface for authentication user to enable mocking in tests
abstract class IUser {
  /// User's unique identifier
  String get uid;
}
