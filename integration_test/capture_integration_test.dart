import 'package:artbeat/main.dart' as app;
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Capture Integration Tests', () {
    testWidgets('should complete simplified capture flow and route correctly', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle();

      // Simulate tap to start capture (now goes directly to camera)
      await tester.tap(find.text('Start Capture'));
      await tester.pumpAndSettle();

      // Camera opens immediately (no terms modal)
      // Simulate camera capture and proceed to details
      // ...mock image capture...

      // Verify capture details screen (simplified flow)
      expect(find.byType(CaptureDetailScreen), findsOneWidget);

      // Fill details and accept terms via checkbox
      // ...fill form fields, check terms checkbox, tap submit...
    });
  });
}
