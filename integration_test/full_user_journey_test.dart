import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../lib/app.dart';
import 'helpers/mock_image_helper.dart';
import 'helpers/test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end user journey test', () {
    setUpAll(() async {
      await TestConfig.setupTestFirebase();
      await TestConfig.cleanupTestData();
    });

    tearDownAll(() async {
      await TestConfig.cleanupTestData();
    });

    testWidgets(
      'Complete user journey: Register -> Login -> Capture -> Upload -> View',
      (WidgetTester tester) async {
        // Build our app and trigger a frame
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        // We should start on the login screen
        expect(find.byKey(const Key('login_email_field')), findsOneWidget);

        // Go to register screen
        await tester.tap(find.byKey(const Key('go_to_register_button')));
        await tester.pumpAndSettle();

        // Register new user
        await tester.enterText(
          find.byKey(const Key('register_email_field')),
          'test_user@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('register_password_field')),
          'Test@123',
        );
        await tester.enterText(
          find.byKey(const Key('register_confirm_password_field')),
          'Test@123',
        );
        await tester.tap(find.byKey(const Key('register_submit_button')));
        await tester.pumpAndSettle();

        // Handle onboarding if present
        if (find
            .byKey(const Key('onboarding_next_button'))
            .evaluate()
            .isNotEmpty) {
          while (find
              .byKey(const Key('onboarding_next_button'))
              .evaluate()
              .isNotEmpty) {
            await tester.tap(find.byKey(const Key('onboarding_next_button')));
            await tester.pumpAndSettle();
          }
        }

        // Verify we're on the dashboard
        expect(find.byKey(const Key('dashboard_screen')), findsOneWidget);

        // Navigate to capture screen
        await tester.tap(find.byKey(const Key('capture_button')));
        await tester.pumpAndSettle();

        // Set up mock image picker
        final mockImage = await MockImageHelper.getTestImage();
        final binding = tester.binding;
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/image_picker'),
          (call) async {
            if (call.method == 'pickImage') {
              return mockImage.path;
            }
            return null;
          },
        );

        // Select and upload image
        await tester.tap(find.byKey(const Key('select_image_button')));
        await tester.pumpAndSettle();

        // Add metadata
        await tester.enterText(
          find.byKey(const Key('location_field')),
          'Test Location',
        );
        await tester.enterText(
          find.byKey(const Key('description_field')),
          'Test art capture description',
        );
        await tester.tap(find.byKey(const Key('save_capture_button')));
        await tester.pumpAndSettle();

        // Wait for upload
        await tester.pump(const Duration(seconds: 2));

        // Verify in recent uploads on dashboard
        await tester.tap(find.byKey(const Key('dashboard_tab')));
        await tester.pumpAndSettle();

        // Check for the uploaded capture in recent uploads
        final uploadedCapture = find.byKey(const Key('recent_upload_0'));
        expect(uploadedCapture, findsOneWidget);

        // Verify in user profile
        await tester.tap(find.byKey(const Key('profile_tab')));
        await tester.pumpAndSettle();

        // We should see the capture in the user's profile gallery
        expect(find.byKey(const Key('profile_capture_0')), findsOneWidget);

        // Navigate to Art Walk map
        await tester.tap(find.byKey(const Key('art_walk_tab')));
        await tester.pumpAndSettle();

        // Wait for map to load
        await tester.pump(const Duration(seconds: 2));

        // Verify map marker exists for the uploaded capture
        expect(find.byKey(const Key('map_marker_0')), findsOneWidget);

        // Tap the marker to verify capture details
        await tester.tap(find.byKey(const Key('map_marker_0')));
        await tester.pumpAndSettle();

        // Verify capture details in map popup
        expect(find.text('Test Location'), findsOneWidget);
        expect(find.text('Test art capture description'), findsOneWidget);
      },
      timeout: const Timeout(
          Duration(minutes: 5)), // Extended timeout for network operations
    );
  });
}
