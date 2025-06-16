import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_settings/src/services/enhanced_settings_service.dart';
import 'package:artbeat_settings/src/interfaces/i_auth_service.dart';
import 'package:artbeat_settings/src/interfaces/i_firestore_service.dart';

// Simple mock implementation for document data
class MockData {
  final Map<String, dynamic> _data;
  MockData(this._data);
  Map<String, dynamic> toMap() => _data;
}

void main() {
  late MockIAuthService mockAuthService;
  late MockIFirestoreService mockFirestoreService;
  late EnhancedSettingsService settingsService;
  late MockUser mockUser;
  late MockDocumentSnapshot mockDocSnapshot;

  setUp(() {
    mockAuthService = MockIAuthService();
    mockFirestoreService = MockIFirestoreService();
    mockUser = MockUser(uid: 'test-user-id');
    mockDocSnapshot = MockDocumentSnapshot();

    // Set up mock auth service
    when(mockAuthService.currentUser).thenReturn(mockUser);

    // Set up mock firestore service
    when(mockFirestoreService.getDocument('users', 'test-user-id'))
        .thenAnswer((_) async => mockDocSnapshot);

    // Initialize settings service with mocks
    settingsService = EnhancedSettingsService(
      authService: mockAuthService,
      firestoreService: mockFirestoreService,
    );
  });

  // Test user account settings
  test('Should get user account settings', () async {
    // Set up mock document response
    final mockAccountData = {
      'email': 'test@example.com',
      'fullName': 'Test User',
      'phoneNumber': '+15551234567',
    };

    when(mockDocSnapshot.exists).thenReturn(true);
    when(mockDocSnapshot.data()).thenReturn(mockAccountData);

    // Call the method and verify result
    final accountSettings = await settingsService.getUserAccountSettings();

    expect(accountSettings['email'], 'test@example.com');
    expect(accountSettings['fullName'], 'Test User');
    expect(accountSettings['phoneNumber'], '+15551234567');
  });

  // Test notification settings
  test('Should get notification settings', () async {
    // Set up mock document response
    final mockData = {
      'notificationPreferences': {
        'email': true,
        'push': false,
        'inApp': true,
      },
    };

    when(mockDocSnapshot.exists).thenReturn(true);
    when(mockDocSnapshot.data()).thenReturn(mockData);

    // Call the method and verify result
    final settings = await settingsService.getNotificationSettings();

    expect(settings['email'], true);
    expect(settings['push'], false);
    expect(settings['inApp'], true);
  });

  // Test privacy settings
  test('Should get privacy settings', () async {
    // Set up mock document response
    final mockData = {
      'privacySettings': {
        'profileVisibility': 'public',
        'allowMessages': true,
        'showLocation': false,
      },
    };

    when(mockDocSnapshot.exists).thenReturn(true);
    when(mockDocSnapshot.data()).thenReturn(mockData);

    // Call the method and verify result
    final settings = await settingsService.getPrivacySettings();

    expect(settings['profileVisibility'], 'public');
    expect(settings['allowMessages'], true);
    expect(settings['showLocation'], false);
  });

  // Test blocked users
  test('Should get blocked users', () async {
    // Set up mock document response
    final mockData = {
      'blockedUsers': ['user-123', 'user-456'],
    };

    when(mockDocSnapshot.exists).thenReturn(true);
    when(mockDocSnapshot.data()).thenReturn(mockData);

    // Call the method and verify result
    final blockedUsers = await settingsService.getBlockedUsers();

    expect(blockedUsers.length, 2);
    expect(blockedUsers.contains('user-123'), true);
    expect(blockedUsers.contains('user-456'), true);
  });

  // Test device activity
  test('Should get device activity', () async {
    // Set up mock document response
    final mockData = {
      'deviceActivity': [
        {
          'deviceName': 'iPhone 13',
          'lastLogin': Timestamp.fromDate(DateTime(2025, 6, 15, 10, 30)),
          'location': 'San Francisco, CA',
          'deviceId': 'device-123',
          'isCurrentDevice': true,
        },
        {
          'deviceName': 'MacBook Pro',
          'lastLogin': Timestamp.fromDate(DateTime(2025, 6, 14, 15, 45)),
          'location': 'San Francisco, CA',
          'deviceId': 'device-456',
          'isCurrentDevice': false,
        }
      ]
    };

    when(mockDocSnapshot.exists).thenReturn(true);
    when(mockDocSnapshot.data()).thenReturn(mockData);

    // Call the method and verify result
    final deviceActivity = await settingsService.getDeviceActivity();

    expect(deviceActivity.length, 2);
    expect(deviceActivity[0]['deviceName'], 'iPhone 13');
    expect(deviceActivity[1]['deviceName'], 'MacBook Pro');
    expect(deviceActivity[0]['isCurrentDevice'], true);
  });
}
