import 'package:artbeat_auth/src/screens/login_screen.dart';
import 'package:artbeat_auth/src/screens/register_screen.dart';
import 'package:artbeat_auth/src/screens/forgot_password_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers/firebase_test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Journey Tests', () {
    late FirebaseAuth auth;
    late FirebaseFirestore db;
    final navigatorKey = GlobalKey<NavigatorState>();

    setUpAll(() async {
      // Initialize and configure Firebase for testing
      await FirebaseTestConfig.setupFirebaseForTesting();
      await FirebaseTestConfig.configureFirebaseAuth();
      await FirebaseTestConfig.configureFirebaseFirestore();

      auth = FirebaseAuth.instance;
      db = FirebaseFirestore.instance;
    });

    setUp(() async {
      // Clean data before each test
      await FirebaseTestConfig.cleanupFirebaseData();
      await auth.signOut();
    });

    testWidgets('Complete registration and login flow',
        (WidgetTester tester) async {
      // Build the app with proper Overlay support
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData(
            appBarTheme: const AppBarTheme(
              toolbarHeight: kToolbarHeight,
            ),
          ),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
              case '/login':
                return MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                  settings: settings,
                );
              case '/register':
                return MaterialPageRoute(
                  builder: (context) => const RegisterScreen(),
                  settings: settings,
                );
              case '/forgot-password':
                return MaterialPageRoute(
                  builder: (context) => const ForgotPasswordScreen(),
                  settings: settings,
                );
              case '/dashboard':
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Dashboard')),
                    body: const Center(child: Text('Dashboard')),
                  ),
                  settings: settings,
                );
              default:
                return null;
            }
          },
          home: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify we start at login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Fill in login form
      await tester.enterText(
          find.byKey(const Key('emailField')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('passwordField')), 'password123');
      await tester.pumpAndSettle();

      // Try to login (should fail)
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();

      // Go to registration
      await tester.tap(find.byKey(const Key('registerButton')));
      await tester.pumpAndSettle();

      // Fill registration form
      await tester.enterText(find.byKey(const Key('nameField')), 'Test User');
      await tester.enterText(
          find.byKey(const Key('emailField')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('passwordField')), 'password123');
      await tester.enterText(
          find.byKey(const Key('confirmPasswordField')), 'password123');
      await tester.pumpAndSettle();

      // Submit registration
      await tester.tap(find.byKey(const Key('registerButton')));
      await tester.pumpAndSettle(
          const Duration(seconds: 2)); // Allow time for Firebase operation

      // Should reach dashboard
      expect(find.text('Dashboard'), findsOneWidget);

      // Return to login
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Login with new account
      await tester.enterText(
          find.byKey(const Key('emailField')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('passwordField')), 'password123');
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle(
          const Duration(seconds: 2)); // Allow time for Firebase operation

      // Should reach dashboard again
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('Password reset flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
              case '/login':
                return MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                  settings: settings,
                );
              case '/forgot-password':
                return MaterialPageRoute(
                  builder: (context) => const ForgotPasswordScreen(),
                  settings: settings,
                );
              default:
                return null;
            }
          },
          home: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Go to forgot password
      await tester.tap(find.byKey(const Key('forgotPasswordButton')));
      await tester.pumpAndSettle();

      // Fill and submit reset form
      await tester.enterText(
          find.byKey(const Key('resetEmailField')), 'test@example.com');
      await tester.tap(find.byKey(const Key('submitResetButton')));
      await tester.pumpAndSettle(
          const Duration(seconds: 2)); // Allow time for Firebase operation

      // Verify success message
      expect(find.text('Password reset email sent'), findsOneWidget);
    });
  });
}
