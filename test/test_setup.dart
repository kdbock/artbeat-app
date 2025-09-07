import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Common test setup utilities for Flutter tests
class TestSetup {
  static bool _isInitialized = false;

  /// Initialize Flutter test bindings and mock platform channels
  static Future<void> initializeTestBindings() async {
    if (_isInitialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock Firebase Core channels to prevent actual initialization
    const firebaseCoreChannel = MethodChannel(
      'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeCore',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseCoreChannel, (MethodCall call) async {
          // Return null to indicate the method is not implemented (prevents actual Firebase initialization)
          return null;
        });

    const firebaseHostApiChannel = MethodChannel(
      'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseHostApiChannel, (
          MethodCall call,
        ) async {
          // Return null to indicate the method is not implemented
          return null;
        });

    // Mock path_provider plugin methods to prevent MissingPluginException
    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (MethodCall call) async {
          if (call.method == 'getTemporaryDirectory' ||
              call.method == 'getApplicationSupportDirectory' ||
              call.method == 'getApplicationDocumentsDirectory') {
            return '/tmp/test';
          }
          return null;
        });

    // Mock Firebase Storage channels
    const firebaseStorageChannel = MethodChannel(
      'plugins.flutter.io/firebase_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseStorageChannel, (
          MethodCall call,
        ) async {
          if (call.method == 'FirebaseStorage#initializeApp') {
            return null;
          }
          if (call.method == 'Reference#getDownloadURL') {
            return 'https://example.com/test-image.jpg';
          }
          if (call.method == 'Reference#putFile') {
            return {'path': 'test-path'};
          }
          return null;
        });

    // Mock Firebase Auth channels
    const firebaseAuthChannel = MethodChannel(
      'plugins.flutter.io/firebase_auth',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseAuthChannel, (MethodCall call) async {
          if (call.method == 'FirebaseAuth#initializeApp') {
            return null;
          }
          if (call.method == 'FirebaseAuth#currentUser') {
            return {
              'user': {
                'uid': 'test-user-id',
                'email': 'test@example.com',
                'displayName': 'Test User',
              },
            };
          }
          return null;
        });

    // Mock shared_preferences to prevent MissingPluginException
    const sharedPrefsChannel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sharedPrefsChannel, (MethodCall call) async {
          if (call.method == 'getAll') {
            return {};
          }
          if (call.method == 'setString') {
            return true;
          }
          if (call.method == 'setBool') {
            return true;
          }
          return null;
        });

    // Mock Firebase app initialization to prevent service access errors
    const firebaseAppChannel = MethodChannel(
      'plugins.flutter.io/firebase_core',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseAppChannel, (MethodCall call) async {
          if (call.method == 'Firebase#initializeApp') {
            return {
              'name': '[DEFAULT]',
              'options': {
                'apiKey': 'test-api-key',
                'appId': 'test-app-id',
                'projectId': 'test-project-id',
              },
            };
          }
          if (call.method == 'Firebase#app') {
            return {
              'name': '[DEFAULT]',
              'options': {
                'apiKey': 'test-api-key',
                'appId': 'test-app-id',
                'projectId': 'test-project-id',
              },
            };
          }
          return null;
        });

    // Skip Firebase initialization for tests - use mocks instead
    // Firebase.initializeApp() will be mocked by individual test mocks

    _isInitialized = true;
  }

  /// Clean up test bindings
  static void cleanupTestBindings() {
    const firebaseCoreChannel = MethodChannel(
      'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeCore',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseCoreChannel, null);

    const firebaseHostApiChannel = MethodChannel(
      'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseHostApiChannel, null);

    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);

    const firebaseStorageChannel = MethodChannel(
      'plugins.flutter.io/firebase_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseStorageChannel, null);

    const firebaseAuthChannel = MethodChannel(
      'plugins.flutter.io/firebase_auth',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseAuthChannel, null);

    const sharedPrefsChannel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sharedPrefsChannel, null);

    const firebaseAppChannel = MethodChannel(
      'plugins.flutter.io/firebase_core',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseAppChannel, null);

    _isInitialized = false;
  }
}
