import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Handles server-side purchase verification for both Google Play and App Store
///
/// IMPORTANT: This service now uses Firebase Cloud Functions for secure verification.
/// Service account credentials are stored securely in Cloud Functions, not in the client app.
class PurchaseVerificationService {
  static const String _cloudFunctionBaseUrl =
      'https://us-central1-wordnerd-artbeat.cloudfunctions.net';

  /// Verify Android purchase via Cloud Function
  ///
  /// This method calls a secure Cloud Function that has access to service account
  /// credentials. The credentials are never exposed to the client app.
  static Future<bool> verifyGooglePlayPurchase({
    required String packageName,
    required String productId,
    required String purchaseToken,
  }) async {
    try {
      AppLogger.info('🔐 Verifying Google Play purchase: $productId');

      // Call Cloud Function for verification
      final response = await http.post(
        Uri.parse('$_cloudFunctionBaseUrl/verifyGooglePlayPurchase'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'packageName': packageName,
          'productId': productId,
          'purchaseToken': purchaseToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final isValid = data['valid'] as bool? ?? false;

        if (isValid) {
          AppLogger.info('✅ Google Play purchase verified: $productId');
        } else {
          AppLogger.warning('⚠️ Google Play purchase not valid');
        }

        return isValid;
      } else {
        AppLogger.error(
          '❌ Verification failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Error verifying Google Play purchase: $e');
      return false;
    }
  }

  /// Verify iOS purchase via Cloud Function
  ///
  /// This method calls a secure Cloud Function that has access to the
  /// App Store shared secret. The secret is never exposed to the client app.
  static Future<bool> verifyAppStorePurchase({
    required String receiptData,
    required String productId,
    required String userId,
  }) async {
    try {
      AppLogger.info('🔐 Verifying App Store purchase for product: $productId');

      // Call Cloud Function for verification
      final response = await http.post(
        Uri.parse('$_cloudFunctionBaseUrl/validateAppleReceipt'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'receiptData': receiptData,
          'userId': userId,
          'productId': productId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final success = data['success'] as bool? ?? false;

        if (success) {
          AppLogger.info('✅ App Store purchase verified: $productId');
        } else {
          AppLogger.warning('⚠️ App Store purchase not valid');
        }

        return success;
      } else {
        AppLogger.error(
          '❌ Verification failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Error verifying App Store purchase: $e');
      return false;
    }
  }

  // DEPRECATED: Old client-side verification methods removed for security
  // All purchase verification must now go through Cloud Functions
  // See functions/src/purchaseVerification.js for server-side implementation
}
