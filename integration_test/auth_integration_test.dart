import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:artbeat/main.dart' as app; // Your main app

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Integration Tests', () {
    testWidgets('should handle complete login flow with real Firebase', (
      tester,
    ) async {
      // Launch the real app
      app.main();
      await tester.pumpAndSettle();

      // Test real login flow
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Verify real authentication happened
      expect(find.text('Welcome'), findsOneWidget);
    });

    testWidgets('should register new user with real Firebase', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test real registration flow with actual Firebase calls
      // This will create real users in your Firebase project
    });
  });
}
