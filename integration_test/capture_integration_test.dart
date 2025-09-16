import 'package:artbeat/main.dart' as app;
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Capture Integration Tests', () {
    testWidgets('should complete capture flow and route correctly', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // Simulate tap to start capture
      await tester.tap(find.text('Start Capture'));
      await tester.pumpAndSettle();

      // Accept terms
      await tester.tap(find.text('Accept & Continue'));
      await tester.pumpAndSettle();

      // Simulate camera, details, and submit
      // ...mock image, fill details, tap submit...

      // Verify confirmation screen
      expect(find.byType(CaptureConfirmationScreen), findsOneWidget);
    });
  });
}
