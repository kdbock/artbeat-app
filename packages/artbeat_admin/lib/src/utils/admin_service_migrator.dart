import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Admin Service Migration Utility
///
/// This utility helps migrate admin functions from other packages into the
/// consolidated admin service, providing a smooth transition path.
class AdminServiceMigrator {
  static const String _migrationCollection = 'adminMigrationLog';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Track migration of admin functions from other packages
  Future<void> logFunctionMigration({
    required String sourcePackage,
    required String functionName,
    required String targetService,
    String? notes,
  }) async {
    try {
      await _firestore.collection(_migrationCollection).add({
        'sourcePackage': sourcePackage,
        'functionName': functionName,
        'targetService': targetService,
        'migratedAt': FieldValue.serverTimestamp(),
        'notes': notes,
        'status': 'migrated',
      });
    } catch (e) {
      AppLogger.error('Error logging migration: $e');
    }
  }

  /// Create deprecation warnings for old admin functions
  static void deprecationWarning(
      String packageName, String functionName, String replacement) {
    debugPrint('''
    ⚠️  DEPRECATION WARNING ⚠️
    Package: $packageName
    Function: $functionName
    
    This admin function has been moved to the consolidated admin service.
    Please use: $replacement
    
    This function will be removed in a future version.
    ''');
  }

  /// Migration checklist for admin functions
  static Map<String, Map<String, dynamic>> getMigrationChecklist() {
    return {
      'artbeat_messaging': {
        'AdminMessagingService': {
          'status': 'pending',
          'functions': [
            'getMessagingStats()',
            'getFlaggedMessages()',
            'moderateMessage()',
          ],
          'targetService': 'ConsolidatedAdminService',
          'priority': 'high',
        },
      },
      'artbeat_capture': {
        'AdminContentModerationScreen': {
          'status': 'pending',
          'functions': [
            'getPendingContent()',
            'moderateContent()',
            'getContentStats()',
          ],
          'targetService': 'ConsolidatedAdminService',
          'priority': 'high',
        },
      },
      'artbeat_ads': {
        'AdminAdManager': {
          'status': 'pending',
          'functions': [
            'getPendingRefundRequests()',
            'processRefundRequest()',
            'getAdAnalytics()',
          ],
          'targetService': 'ConsolidatedAdminService',
          'priority': 'medium',
        },
        'DeveloperFeedbackAdminScreen': {
          'status': 'pending',
          'functions': [
            'getFeedbackRequests()',
            'processFeedback()',
          ],
          'targetService': 'ConsolidatedAdminService',
          'priority': 'low',
        },
      },
      'artbeat_core': {
        'AdminUploadScreens': {
          'status': 'pending',
          'functions': [
            'handleAdminUploads()',
            'validateAdminContent()',
          ],
          'targetService': 'ConsolidatedAdminService',
          'priority': 'medium',
        },
      },
    };
  }

  /// Generate migration report
  Future<Map<String, dynamic>> generateMigrationReport() async {
    try {
      final migrationDocs = await _firestore
          .collection(_migrationCollection)
          .orderBy('migratedAt', descending: true)
          .get();

      final migratedFunctions = migrationDocs.docs.length;
      final checklist = getMigrationChecklist();

      int totalFunctions = 0;
      for (final package in checklist.values) {
        for (final service in package.values) {
          if (service['functions'] != null) {
            totalFunctions += (service['functions'] as List).length;
          }
        }
      }

      final completionPercentage = totalFunctions > 0
          ? (migratedFunctions / totalFunctions * 100).round()
          : 0;

      return {
        'totalFunctions': totalFunctions,
        'migratedFunctions': migratedFunctions,
        'completionPercentage': completionPercentage,
        'pendingMigrations': checklist,
        'recentMigrations': migrationDocs.docs.take(10).map((doc) {
          final data = doc.data();
          return {
            ...data,
            'migrationId': doc.id,
          };
        }).toList(),
      };
    } catch (e) {
      AppLogger.error('Error generating migration report: $e');
      return {
        'error': e.toString(),
        'completionPercentage': 0,
      };
    }
  }
}

/// Wrapper for deprecated admin functions from artbeat_messaging
@Deprecated('Use ConsolidatedAdminService.getMessagingStats() instead')
class DeprecatedMessagingAdminService {
  static void _showDeprecationWarning() {
    AdminServiceMigrator.deprecationWarning(
        'artbeat_messaging',
        'AdminMessagingService',
        'ConsolidatedAdminService from artbeat_admin package');
  }

  @Deprecated('Use ConsolidatedAdminService.getMessagingStats()')
  static Future<Map<String, dynamic>> getMessagingStats() async {
    _showDeprecationWarning();
    // Return empty data or redirect to new service
    return {};
  }

  @Deprecated('Use ConsolidatedAdminService.getFlaggedMessages()')
  static Future<List<Map<String, dynamic>>> getFlaggedMessages() async {
    _showDeprecationWarning();
    return [];
  }
}

/// Wrapper for deprecated admin functions from artbeat_capture
@Deprecated('Use AdminCommunityModerationScreen from artbeat_admin instead')
class DeprecatedCaptureAdminService {
  static void _showDeprecationWarning() {
    AdminServiceMigrator.deprecationWarning(
        'artbeat_capture',
        'AdminContentModerationScreen',
        'AdminCommunityModerationScreen from artbeat_admin package');
  }

  @Deprecated('Use ConsolidatedAdminService.getPendingContent()')
  static Future<Map<String, dynamic>> getPendingContent() async {
    _showDeprecationWarning();
    return {};
  }
}

/// Wrapper for deprecated admin functions from artbeat_ads
@Deprecated('Use ConsolidatedAdminService for ad administration')
class DeprecatedAdsAdminService {
  static void _showDeprecationWarning() {
    AdminServiceMigrator.deprecationWarning('artbeat_ads', 'AdminAdManager',
        'ConsolidatedAdminService from artbeat_admin package');
  }

  @Deprecated('Use ConsolidatedAdminService.getPendingRefundRequests()')
  static Future<List<Map<String, dynamic>>> getPendingRefundRequests() async {
    _showDeprecationWarning();
    return [];
  }

  @Deprecated('Use ConsolidatedAdminService.processRefundRequest()')
  static Future<bool> processRefundRequest(
      String requestId, bool approve) async {
    _showDeprecationWarning();
    return false;
  }
}

/// Migration instructions for developers
class MigrationInstructions {
  static const String migrationGuide = '''
# Admin Function Migration Guide

## Overview
Admin functions are being consolidated into the artbeat_admin package for better maintainability and consistency.

## Migration Steps

### 1. Update Dependencies
Add artbeat_admin to your pubspec.yaml:
```yaml
dependencies:
  artbeat_admin:
    path: ../artbeat_admin
```

### 2. Update Imports
Replace old imports:
```dart
// OLD
import 'package:artbeat_messaging/artbeat_messaging.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_ads/artbeat_ads.dart';

// NEW
import 'package:artbeat_admin/artbeat_admin.dart';
```

### 3. Update Service Usage
Replace old service calls:
```dart
// OLD
final messagingService = AdminMessagingService();
final stats = await messagingService.getMessagingStats();

// NEW
final adminService = ConsolidatedAdminService();
final stats = await adminService.getMessagingStats();
```

### 4. Update Screen Navigation
Replace old admin screens:
```dart
// OLD
Navigator.pushNamed(context, '/capture/admin/moderation');

// NEW
Navigator.pushNamed(context, '/admin/content-management-suite');
```

## Benefits of Migration
- Centralized admin functionality
- Consistent UI/UX across admin features
- Better security and access control
- Improved maintainability
- Single source of truth for admin operations

## Support
Contact the development team for migration assistance.
''';

  static void printMigrationGuide() {
    AppLogger.info(migrationGuide);
  }
}
