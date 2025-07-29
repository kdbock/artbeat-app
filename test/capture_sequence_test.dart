import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/src/screens/camera_capture_screen.dart';
import 'package:artbeat_capture/src/screens/capture_details_screen.dart';
import 'package:artbeat_capture/src/screens/capture_confirmation_screen.dart';
import 'package:artbeat_capture/src/services/capture_service.dart';
import 'package:artbeat_capture/src/services/storage_service.dart';

import 'capture_sequence_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  User,
  UserService,
  CaptureService,
  StorageService,
])
void main() {
  group('Capture Sequence Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockUserService mockUserService;
    late MockCaptureService mockCaptureService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockUserService = MockUserService();
      mockCaptureService = MockCaptureService();
      mockStorageService = MockStorageService();

      // Setup mock user
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockAuth.currentUser).thenReturn(mockUser);

      // Setup mock user service
      when(mockUserService.currentUser).thenReturn(mockUser);
      when(mockUserService.getCurrentUserModel()).thenAnswer(
        (_) async => UserModel(
          id: 'test-user-id',
          email: 'test@example.com',
          username: 'testuser',
          fullName: 'Test User',
          createdAt: DateTime.now(),
        ),
      );
    });

    testWidgets('Complete capture sequence should work correctly', (
      tester,
    ) async {
      // Create a test image file
      final testImageFile = File('test_image.jpg');

      // Mock storage service upload
      when(
        mockStorageService.uploadCaptureImage(any, any),
      ).thenAnswer((_) async => 'https://example.com/test-image.jpg');

      // Mock capture service create
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

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<UserService>.value(value: mockUserService),
            Provider<CaptureService>.value(value: mockCaptureService),
            Provider<StorageService>.value(value: mockStorageService),
          ],
          child: MaterialApp(
            routes: {
              '/dashboard': (context) =>
                  const Scaffold(body: Center(child: Text('Fluid Dashboard'))),
            },
            home: const BasicCaptureScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Verify terms modal appears
      expect(find.text('Before You Capture'), findsOneWidget);
      expect(find.text('Accept & Continue'), findsOneWidget);

      // Accept terms (checkbox should be checked first)
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept & Continue'));
      await tester.pumpAndSettle();

      // Note: In a real test, we'd need to mock the camera functionality
      // For now, we'll simulate having an image by directly navigating to details

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<UserService>.value(value: mockUserService),
            Provider<CaptureService>.value(value: mockCaptureService),
            Provider<StorageService>.value(value: mockStorageService),
          ],
          child: MaterialApp(
            routes: {
              '/dashboard': (context) =>
                  const Scaffold(body: Center(child: Text('Fluid Dashboard'))),
            },
            home: CaptureDetailsScreen(imageFile: testImageFile),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 2: Verify capture details screen
      expect(find.text('Add Details'), findsOneWidget);
      expect(find.text('Title *'), findsOneWidget);

      // Fill in required title field
      await tester.enterText(find.byType(TextFormField).first, 'Test Artwork');
      await tester.pumpAndSettle();

      // Tap continue to review
      await tester.tap(find.text('Continue to Review'));
      await tester.pumpAndSettle();

      // Step 3: Verify confirmation screen
      expect(find.text('Review Capture'), findsOneWidget);
      expect(find.text('Title: Test Artwork'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);

      // Submit the capture
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Step 4: Verify navigation to dashboard
      // The navigation should happen after successful upload
      expect(find.text('Fluid Dashboard'), findsOneWidget);

      // Verify the services were called correctly
      verify(mockStorageService.uploadCaptureImage(any, any)).called(1);
      verify(mockCaptureService.createCapture(any)).called(1);
    });

    testWidgets('Capture sequence should handle errors gracefully', (
      tester,
    ) async {
      final testImageFile = File('test_image.jpg');

      // Mock storage service to throw an error
      when(
        mockStorageService.uploadCaptureImage(any, any),
      ).thenThrow(Exception('Upload failed'));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<UserService>.value(value: mockUserService),
            Provider<CaptureService>.value(value: mockCaptureService),
            Provider<StorageService>.value(value: mockStorageService),
          ],
          child: MaterialApp(
            routes: {
              '/dashboard': (context) =>
                  const Scaffold(body: Center(child: Text('Fluid Dashboard'))),
            },
            home: CaptureConfirmationScreen(
              imageFile: testImageFile,
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
      expect(
        find.text('Failed to submit capture: Exception: Upload failed'),
        findsOneWidget,
      );
      expect(find.text('Review Capture'), findsOneWidget);

      // Should not navigate to dashboard on error
      expect(find.text('Fluid Dashboard'), findsNothing);
    });

    testWidgets('Navigation flow should clear stack correctly', (tester) async {
      final testImageFile = File('test_image.jpg');

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
            Provider<UserService>.value(value: mockUserService),
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
              imageFile: testImageFile,
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

      // Verify that the navigation stack was cleared
      // (In a real app, this would prevent back navigation to capture screens)
      final navigator = navigatorKey.currentState!;
      expect(navigator.canPop(), isFalse);
    });
  });
}
