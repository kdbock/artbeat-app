import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_auth/src/services/auth_service.dart';

void main() {
  group('Firebase Emulator Tests', () {
    late AuthService authService;

    setUpAll(() async {
      // Connect to Firebase Emulator
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'demo-key',
          appId: 'demo-app',
          messagingSenderId: 'demo-sender',
          projectId: 'demo-project',
        ),
      );

      // Connect to Auth Emulator
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

      authService = AuthService();
    });

    test('should register user with emulator', () async {
      // Test with real Firebase Emulator
      final result = await authService.registerWithEmailAndPassword(
        'test@example.com',
        'password123',
        'Test User',
        zipCode: '00000',
      );

      expect(result, isNotNull);
      expect(result.user!.email, equals('test@example.com'));
    });

    tearDownAll(() async {
      // Clean up emulator data
      await FirebaseAuth.instance.signOut();
    });
  });
}
