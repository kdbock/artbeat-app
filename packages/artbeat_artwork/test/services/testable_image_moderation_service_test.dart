import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:artbeat_artwork/src/services/testable_image_moderation_service.dart';

// Generate mocks with annotations
@GenerateMocks([FirebaseAuth, User, http.Client, http.Response])
@GenerateNiceMocks([MockSpec<File>()])
import 'testable_image_moderation_service_test.mocks.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockFile mockFile;
  late MockClient mockHttpClient;
  late TestableImageModerationService moderationService;

  const testApiKey = 'test-api-key';
  const testUserId = 'test-user-id';

  setUp(() {
    // Set up mocks
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockFile = MockFile();
    mockHttpClient = MockClient();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(testUserId);

    // Create the service with mocked dependencies
    moderationService = TestableImageModerationService(
      apiKey: testApiKey,
      firestore: fakeFirestore,
      auth: mockAuth,
      httpClient: mockHttpClient,
    );
  });

  group('TestableImageModerationService Tests', () {
    test('checkImage should return moderation results when successful',
        () async {
      // Arrange
      final mockResponse = MockResponse();
      final mockResponseBody = jsonEncode({
        'rating_label': 'everyone',
        'rating_score': 0.2,
        'predictions': {
          'adult': 0.01,
          'suggestive': 0.05,
          'violence': 0.02,
        }
      });

      when(mockFile.readAsBytes())
          .thenAnswer((_) async => Uint8List.fromList([1, 2, 3, 4]));
      when(mockResponse.statusCode).thenReturn(200);
      when(mockResponse.body).thenReturn(mockResponseBody);

      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => mockResponse);

      // Act
      final result = await moderationService.checkImage(mockFile);

      // Assert
      expect(result['rating_label'], 'everyone');
      expect(result['rating_score'], 0.2);

      // Verify the Firestore log was created
      final logs = await fakeFirestore.collection('moderation_logs').get();
      expect(logs.docs.length, 1);
      expect(logs.docs.first.data()['userId'], testUserId);
      expect(logs.docs.first.data()['status'], 'completed');
    });

    test('checkImage should throw and log error when API request fails',
        () async {
      // Arrange
      final mockResponse = MockResponse();

      when(mockFile.readAsBytes())
          .thenAnswer((_) async => Uint8List.fromList([1, 2, 3, 4]));
      when(mockResponse.statusCode).thenReturn(400);
      when(mockResponse.body).thenReturn('Bad Request');

      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => mockResponse);

      // Act & Assert
      await expectLater(
        moderationService.checkImage(mockFile),
        throwsException,
      );

      // Verify the error was logged in Firestore
      final logs = await fakeFirestore.collection('moderation_logs').get();
      expect(logs.docs.length, 1);
      expect(logs.docs.first.data()['userId'], testUserId);
      expect(logs.docs.first.data()['status'], 'error');
      expect(logs.docs.first.data()['error'],
          contains('Failed to moderate image: 400'));
    });

    test(
        'verifyArtworkContent returns isVerified value if artwork is already verified',
        () async {
      // Arrange
      final testArtworkId = 'test-artwork-id';

      // Setup test data - artwork already verified
      await fakeFirestore.collection('artwork').doc(testArtworkId).set({
        'title': 'Test Artwork',
        'isVerified': true,
      });

      // Act
      final result =
          await moderationService.verifyArtworkContent(testArtworkId);

      // Assert
      expect(result, isTrue);
    });

    test(
        'verifyArtworkContent updates verification status if artwork not verified',
        () async {
      // Arrange
      final testArtworkId = 'test-artwork-id';

      // Setup test data - artwork not verified yet
      await fakeFirestore.collection('artwork').doc(testArtworkId).set({
        'title': 'Test Artwork',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Act
      final result =
          await moderationService.verifyArtworkContent(testArtworkId);

      // Assert
      expect(result, isFalse);

      // Verify the artwork document was updated
      final artwork =
          await fakeFirestore.collection('artwork').doc(testArtworkId).get();
      expect(artwork.data()?['verificationStatus'], 'pending');
    });

    test('verifyArtworkContent throws exception if artwork not found',
        () async {
      // Arrange
      final nonExistentArtworkId = 'non-existent-id';

      // Act & Assert
      await expectLater(
        moderationService.verifyArtworkContent(nonExistentArtworkId),
        throwsException,
      );
    });
  });
}
