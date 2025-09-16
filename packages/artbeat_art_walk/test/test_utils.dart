import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:artbeat_core/artbeat_core.dart';

// Generate mocks for Firebase services and providers
@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  FirebaseStorage,
  User,
  UserCredential,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  Query,
  Reference,
  MessagingProvider,
])
import 'test_utils.mocks.dart';

/// Test utilities for Firebase mocking in Art Walk module
class TestUtils {
  static const String testProjectId = 'test-project';
  static const String testUserId = 'test-user-id';
  static const String testEmail = 'test@example.com';

  /// Initialize Firebase for testing (for service tests only)
  static Future<void> initializeFirebaseForTesting() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Set up environment variables for testing
    setupTestEnvironmentVariables();

    // Setup Firebase platform channel mocks
    setupFirebasePlatformChannelMocks();

    try {
      // Initialize Firebase with test configuration
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-sender-id',
          projectId: testProjectId,
        ),
      );
    } catch (e) {
      // Firebase might already be initialized, which is fine for tests
      if (!e.toString().contains('already exists')) {
        rethrow;
      }
    }
  }

  /// Initialize test environment for widget tests (without Firebase)
  static void initializeWidgetTesting() {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupTestEnvironmentVariables();
    setupFirebasePlatformChannelMocks();
  }

  /// Setup Firebase platform channel mocks
  static void setupFirebasePlatformChannelMocks() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_core'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'Firebase#initializeCore') {
              return [
                {
                  'name': '[DEFAULT]',
                  'options': {
                    'apiKey': 'test-api-key',
                    'appId': 'test-app-id',
                    'messagingSenderId': 'test-sender-id',
                    'projectId': testProjectId,
                  },
                  'pluginConstants': <String, String>{},
                },
              ];
            }
            if (methodCall.method == 'Firebase#initializeApp') {
              return {
                'name': methodCall.arguments['appName'] ?? '[DEFAULT]',
                'options': methodCall.arguments['options'],
                'pluginConstants': <String, String>{},
              };
            }
            return null;
          },
        );

    // Mock Firebase Auth
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_auth'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'Auth#registerIdTokenListener') {
              return <String, dynamic>{'user': null};
            }
            if (methodCall.method == 'Auth#registerAuthStateListener') {
              return <String, dynamic>{'user': null};
            }
            return null;
          },
        );

    // Mock Firestore
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/cloud_firestore'),
          (MethodCall methodCall) async {
            return null;
          },
        );

    // Mock Firebase Storage
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_storage'),
          (MethodCall methodCall) async {
            return null;
          },
        );
  }

  /// Setup test environment variables
  static void setupTestEnvironmentVariables() {
    // Mock environment variables that tests need
    // const mockEnvVars = {
    //   'GOOGLE_MAPS_API_KEY': 'test-google-maps-key',
    //   'SECURE_DIRECTIONS_ENDPOINT': 'https://test-endpoint.com',
    //   'DIRECTIONS_API_KEY_HASH': 'test-hash-key',
    // };

    // You might need to use a different approach based on how your app reads config
    // This is a placeholder - implement based on your config system
  }

  /// Create a mock authenticated user
  static MockUser createMockUser({
    String? uid,
    String? email,
    String? displayName,
  }) {
    final mockUser = MockUser();
    when(mockUser.uid).thenReturn(uid ?? testUserId);
    when(mockUser.email).thenReturn(email ?? testEmail);
    when(mockUser.displayName).thenReturn(displayName ?? 'Test User');
    when(mockUser.emailVerified).thenReturn(true);
    return mockUser;
  }

  /// Create a mock user credential
  static MockUserCredential createMockUserCredential({MockUser? user}) {
    final mockCredential = MockUserCredential();
    when(mockCredential.user).thenReturn(user ?? createMockUser());
    return mockCredential;
  }

  /// Setup basic Firestore mocks
  static void setupFirestoreMocks(MockFirebaseFirestore mockFirestore) {
    final mockCollection = MockCollectionReference<Map<String, dynamic>>();
    final mockDocument = MockDocumentReference<Map<String, dynamic>>();
    final mockQuery = MockQuery<Map<String, dynamic>>();
    final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();

    // Setup collection references
    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDocument);

    // Setup query operations
    when(
      mockCollection.where(any, isEqualTo: anyNamed('isEqualTo')),
    ).thenReturn(mockQuery);
    when(
      mockCollection.where(any, arrayContains: anyNamed('arrayContains')),
    ).thenReturn(mockQuery);
    when(
      mockQuery.orderBy(any, descending: anyNamed('descending')),
    ).thenReturn(mockQuery);
    when(mockQuery.limit(any)).thenReturn(mockQuery);
    when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

    // Setup empty results by default
    when(mockSnapshot.docs).thenReturn([]);
    when(mockSnapshot.size).thenReturn(0);
  }

  /// Setup basic Auth mocks
  static void setupAuthMocks(MockFirebaseAuth mockAuth, {MockUser? user}) {
    when(mockAuth.currentUser).thenReturn(user);
    when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(user));
    when(mockAuth.userChanges()).thenAnswer((_) => Stream.value(user));
  }

  /// Setup basic Storage mocks
  static void setupStorageMocks(MockFirebaseStorage mockStorage) {
    // Add basic storage mocking if needed
    final mockReference = MockReference();
    when(mockStorage.ref()).thenReturn(mockReference);
  }

  /// Create a test widget wrapper with all necessary providers
  static Widget createTestWidgetWrapper({
    required Widget child,
    TestEnvironment? testEnv,
  }) {
    final env = testEnv ?? createTestEnvironment();

    return MultiProvider(
      providers: [
        // Create a mock MessagingProvider
        ChangeNotifierProvider<MessagingProvider>(
          create: (_) => MockMessagingProvider(),
        ),
        // Add other providers as needed
        Provider<FirebaseFirestore>.value(value: env.firestore),
        Provider<FirebaseAuth>.value(value: env.auth),
        Provider<FirebaseStorage>.value(value: env.storage),
      ],
      child: MaterialApp(home: child),
    );
  }

  /// Create a mock MessagingProvider
  static MockMessagingProvider createMockMessagingProvider() {
    final mockProvider = MockMessagingProvider();
    // Add any necessary stubbing here
    return mockProvider;
  }

  /// Create a complete test environment with all Firebase services mocked
  static TestEnvironment createTestEnvironment() {
    final mockFirestore = MockFirebaseFirestore();
    final mockAuth = MockFirebaseAuth();
    final mockStorage = MockFirebaseStorage();
    final mockUser = createMockUser();

    setupFirestoreMocks(mockFirestore);
    setupAuthMocks(mockAuth, user: mockUser);
    setupStorageMocks(mockStorage);

    return TestEnvironment(
      firestore: mockFirestore,
      auth: mockAuth,
      storage: mockStorage,
      user: mockUser,
    );
  }
}

/// Container for all mocked Firebase services
class TestEnvironment {
  final MockFirebaseFirestore firestore;
  final MockFirebaseAuth auth;
  final MockFirebaseStorage storage;
  final MockUser user;

  TestEnvironment({
    required this.firestore,
    required this.auth,
    required this.storage,
    required this.user,
  });
}

/// Legacy support functions for backward compatibility
void setupAllFirebaseMocks() {
  // This function is kept for backward compatibility
  // New tests should use TestUtils.createTestEnvironment() instead
  TestUtils.initializeFirebaseForTesting();
}

void setupFirebaseAuthMocks() {
  // Legacy function - use TestUtils.setupAuthMocks() instead
}

void setupFirestoreMocks() {
  // Legacy function - use TestUtils.setupFirestoreMocks() instead
}

void setupFirebaseStorageMocks() {
  // Legacy function - use TestUtils.setupStorageMocks() instead
}
