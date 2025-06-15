import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_settings/src/services/settings_service_for_testing.dart';
import '../mocks/enhanced_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late MockAuthService mockAuthService;
  late MockFirestoreService mockFirestoreService;
  late SettingsServiceForTesting settingsService;
  final testUserId = 'test-user-id';

  setUp(() {
    // Use simplified mocks with pre-filled data
    mockAuthService = MockAuthService(testUserId);
    mockFirestoreService = MockFirestoreService();
    
    // Initialize settings service with mocks
    settingsService = SettingsServiceForTesting(
      authService: mockAuthService,
      firestoreService: mockFirestoreService,
    );
  });

  // Test user account settings
  test('Should get user account settings', () async {
    // Set up mock document data
    mockFirestoreService.addMockDocument('users', testUserId, {
      'email': 'test@example.com',
      'fullName': 'Test User',
      'phoneNumber': '+15551234567',
    });
    
    // Call the method and verify result
    final accountSettings = await settingsService.getUserAccountSettings();
    
    expect(accountSettings['email'], 'test@example.com');
    expect(accountSettings['fullName'], 'Test User');
    expect(accountSettings['phoneNumber'], '+15551234567');
  });
  
  // Test notification settings
  test('Should get notification settings', () async {
    // Set up mock document data
    mockFirestoreService.addMockDocument('users', testUserId, {
      'notificationPreferences': {
        'email': true,
        'push': false,
        'inApp': true,
      }
    });
    
    // Call the method and verify result
    final settings = await settingsService.getNotificationSettings();
    
    expect(settings['email'], true);
    expect(settings['push'], false);
    expect(settings['inApp'], true);
  });
  
  // Test privacy settings
  test('Should get privacy settings', () async {
    // Set up mock document data
    mockFirestoreService.addMockDocument('users', testUserId, {
      'privacySettings': {
        'profileVisibility': 'public',
        'allowMessages': true,
        'showLocation': false,
      }
    });
    
    // Call the method and verify result
    final settings = await settingsService.getPrivacySettings();
    
    expect(settings['profileVisibility'], 'public');
    expect(settings['allowMessages'], true);
    expect(settings['showLocation'], false);
  });
  
  // Test update privacy settings
  test('Should update privacy settings', () async {
    // Initialize with empty settings
    mockFirestoreService.addMockDocument('users', testUserId, {
      'privacySettings': {}
    });
    
    // New settings to apply
    final newSettings = {
      'profileVisibility': 'private',
      'allowMessages': false,
      'showLocation': false
    };
    
    // Call the method
    await settingsService.updatePrivacySettings(newSettings);
    
    // Verify document was updated with correct data
    final doc = await mockFirestoreService.getDocument('users', testUserId);
    final data = doc.data()!;
    final updatedSettings = data['privacySettings'] as Map<String, dynamic>;
    
    expect(updatedSettings['profileVisibility'], 'private');
    expect(updatedSettings['allowMessages'], false);
    expect(updatedSettings['showLocation'], false);
  });
  
  // Test blocked users
  test('Should get blocked users', () async {
    // Set up mock document data
    mockFirestoreService.addMockDocument('users', testUserId, {
      'blockedUsers': ['user-123', 'user-456']
    });
    
    // Call the method and verify result
    final blockedUsers = await settingsService.getBlockedUsers();
    
    expect(blockedUsers.length, 2);
    expect(blockedUsers.contains('user-123'), true);
    expect(blockedUsers.contains('user-456'), true);
  });

  // Test blocking a user
  test('Should block a user', () async {
    // Set up initial data
    mockFirestoreService.addMockDocument('users', testUserId, {
      'blockedUsers': ['user-123']
    });
    
    // Call the method to block a new user
    await settingsService.blockUser('user-456');
    
    // Verify the new user was added to blocked list
    final doc = await mockFirestoreService.getDocument('users', testUserId);
    final data = doc.data()!;
    final blockedUsers = data['blockedUsers'] as List<dynamic>;
    
    expect(blockedUsers.length, 2);
    expect(blockedUsers.contains('user-123'), true);
    expect(blockedUsers.contains('user-456'), true);
  });
  
  // Test unblocking a user
  test('Should unblock a user', () async {
    // Set up initial data
    mockFirestoreService.addMockDocument('users', testUserId, {
      'blockedUsers': ['user-123', 'user-456']
    });
    
    // Call the method to unblock a user
    await settingsService.unblockUser('user-123');
    
    // Verify the user was removed from blocked list
    final doc = await mockFirestoreService.getDocument('users', testUserId);
    final data = doc.data()!;
    final blockedUsers = data['blockedUsers'] as List<dynamic>;
    
    expect(blockedUsers.length, 1);
    expect(blockedUsers.contains('user-123'), false);
    expect(blockedUsers.contains('user-456'), true);
  });

  // Test device activity
  test('Should get device activity', () async {
    // Set up mock document data with device activity
    mockFirestoreService.addMockDocument('users', testUserId, {
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
    });
    
    // Call the method and verify result
    final deviceActivity = await settingsService.getDeviceActivity();
    
    expect(deviceActivity.length, 2);
    expect(deviceActivity[0]['deviceName'], 'iPhone 13');
    expect(deviceActivity[1]['deviceName'], 'MacBook Pro');
    expect(deviceActivity[0]['isCurrentDevice'], true);
  });
  
  // Test revoking device access
  test('Should revoke device access', () async {
    // Set up mock document data with device activity
    mockFirestoreService.addMockDocument('users', testUserId, {
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
    });
    
    // Call method to revoke access
    await settingsService.revokeDeviceAccess('device-456');
    
    // Verify device was removed
    final doc = await mockFirestoreService.getDocument('users', testUserId);
    final data = doc.data()!;
    final deviceActivity = data['deviceActivity'] as List<dynamic>;
    
    expect(deviceActivity.length, 1);
    expect(deviceActivity[0]['deviceId'], 'device-123');
  });
}
