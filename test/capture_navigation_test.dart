import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/src/screens/capture_confirmation_screen.dart';
import 'package:artbeat_capture/src/services/capture_service.dart';
import 'package:artbeat_capture/src/services/storage_service.dart';

import 'capture_navigation_test.mocks.dart';

@GenerateMocks([CaptureService, StorageService])
void main() {
  group('Capture Navigation Tests', () {
    late MockCaptureService mockCaptureService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockCaptureService = MockCaptureService();
      mockStorageService = MockStorageService();
    });

    testWidgets('Should navigate to dashboard after successful upload', (
      tester,
    ) async {
      // Mock successful upload and capture creation
      when(
        mockStorageService.uploadCaptureImage(any, any),
      ).thenAnswer((_) async => 'https://example.com/test-image.jpg');

      when(mockCaptureService.createCapture(any)).thenAnswer(
        (_) async => CaptureModel(
          id: 'test-capture-id',
          userId: 'test-user-id',
          title: 'Test Artwork',
          imageUrl: 'https://example.com/test-image.jpg',
          createdAt: DateTime.now(),
          isPublic: true,
          tags: [],
          status: CaptureStatus.pending,
        ),
      );

      bool dashboardNavigated = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<CaptureService>.value(value: mockCaptureService),
            Provider<StorageService>.value(value: mockStorageService),
          ],
          child: MaterialApp(
            routes: {
              '/dashboard': (context) {
                dashboardNavigated = true;
                return const Scaffold(
                  body: Center(child: Text('Fluid Dashboard')),
                );
              },
            },
            home: CaptureConfirmationScreen(
              imageFile: File('test_image.jpg'),
              captureData: CaptureModel(
                id: '',
                userId: 'test-user-id',
                title: 'Test Artwork',
                imageUrl: '',
                createdAt: DateTime.now(),
                isPublic: true,
                tags: [],
                status: CaptureStatus.pending,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify confirmation screen is displayed
      expect(find.text('Review Capture'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);

      // Submit the capture
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Verify navigation to dashboard occurred
      expect(dashboardNavigated, isTrue);
      expect(find.text('Fluid Dashboard'), findsOneWidget);

      // Verify services were called
      verify(mockStorageService.uploadCaptureImage(any, any)).called(1);
      verify(mockCaptureService.createCapture(any)).called(1);
    });

    testWidgets('Should stay on confirmation screen when upload fails', (
      tester,
    ) async {
      // Mock failed upload
      when(
        mockStorageService.uploadCaptureImage(any, any),
      ).thenThrow(Exception('Upload failed'));

      bool dashboardNavigated = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<CaptureService>.value(value: mockCaptureService),
            Provider<StorageService>.value(value: mockStorageService),
          ],
          child: MaterialApp(
            routes: {
              '/dashboard': (context) {
                dashboardNavigated = true;
                return const Scaffold(
                  body: Center(child: Text('Fluid Dashboard')),
                );
              },
            },
            home: CaptureConfirmationScreen(
              imageFile: File('test_image.jpg'),
              captureData: CaptureModel(
                id: '',
                userId: 'test-user-id',
                title: 'Test Artwork',
                imageUrl: '',
                createdAt: DateTime.now(),
                isPublic: true,
                tags: [],
                status: CaptureStatus.pending,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Submit the capture
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Should show error message and stay on confirmation screen
      expect(find.textContaining('Failed to submit capture'), findsOneWidget);
      expect(find.text('Review Capture'), findsOneWidget);

      // Should not navigate to dashboard
      expect(dashboardNavigated, isFalse);
      expect(find.text('Fluid Dashboard'), findsNothing);
    });

    testWidgets('Should clear navigation stack when navigating to dashboard', (
      tester,
    ) async {
      // Mock successful upload
      when(
        mockStorageService.uploadCaptureImage(any, any),
      ).thenAnswer((_) async => 'https://example.com/test-image.jpg');

      when(mockCaptureService.createCapture(any)).thenAnswer(
        (_) async => CaptureModel(
          id: 'test-capture-id',
          userId: 'test-user-id',
          title: 'Test Artwork',
          imageUrl: 'https://example.com/test-image.jpg',
          createdAt: DateTime.now(),
          isPublic: true,
          tags: [],
          status: CaptureStatus.pending,
        ),
      );

      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<CaptureService>.value(value: mockCaptureService),
            Provider<StorageService>.value(value: mockStorageService),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            routes: {
              '/dashboard': (context) =>
                  const Scaffold(body: Center(child: Text('Fluid Dashboard'))),
            },
            home: CaptureConfirmationScreen(
              imageFile: File('test_image.jpg'),
              captureData: CaptureModel(
                id: '',
                userId: 'test-user-id',
                title: 'Test Artwork',
                imageUrl: '',
                createdAt: DateTime.now(),
                isPublic: true,
                tags: [],
                status: CaptureStatus.pending,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Submit the capture
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Verify navigation to dashboard
      expect(find.text('Fluid Dashboard'), findsOneWidget);

      // Verify navigation stack was cleared (can't pop back)
      final navigator = navigatorKey.currentState!;
      expect(navigator.canPop(), isFalse);
    });
  });
}
