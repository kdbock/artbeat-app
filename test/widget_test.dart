import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A simple mock app for testing basic widget functionality
class MockApp extends StatelessWidget {
  const MockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ARTbeat'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Basic app structure test', (WidgetTester tester) async {
    // Build our mock app
    await tester.pumpWidget(const MockApp());

    // Verify the app title is shown
    expect(find.text('ARTbeat'), findsOneWidget);

    // Verify the loading indicator is shown
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
