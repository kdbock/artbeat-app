import 'dart:convert';
import 'package:http/http.dart' as http;
import '../firebase/secure_firebase_config.dart';
import '../utils/logger.dart';

/// Handles server-side purchase verification for both Google Play and App Store
class PurchaseVerificationService {
  static const String _googlePlayApiUrl =
      'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';
  static const String _appStoreVerifyUrl =
      'https://buy.itunes.apple.com/verifyReceipt';
  static const String _appStoreSandboxVerifyUrl =
      'https://sandbox.itunes.apple.com/verifyReceipt';

  /// Verify Android purchase with Google Play Developer API
  static Future<bool> verifyGooglePlayPurchase({
    required String packageName,
    required String productId,
    required String purchaseToken,
  }) async {
    try {
      AppLogger.info('🔐 Verifying Google Play purchase: $productId');

      // Get access token using service account
      final accessToken = await _getGoogleAccessToken();

      if (accessToken == null) {
        AppLogger.error('❌ Failed to get Google access token');
        return false;
      }

      // Verify purchase with Google Play API
      final url =
          '$_googlePlayApiUrl/$packageName/purchases/products/$productId/tokens/$purchaseToken';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final purchaseState = data['purchaseState'] as int?;

        // purchaseState: 0 = purchased, 1 = canceled, 2 = pending
        if (purchaseState == 0) {
          AppLogger.info('✅ Google Play purchase verified: $productId');
          return true;
        } else {
          AppLogger.warning(
            '⚠️ Google Play purchase not valid: state=$purchaseState',
          );
          return false;
        }
      } else {
        AppLogger.error(
          '❌ Google Play API error: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Error verifying Google Play purchase: $e');
      return false;
    }
  }

  /// Verify iOS purchase with App Store
  static Future<bool> verifyAppStorePurchase({
    required String receiptData,
    required bool isSandbox,
  }) async {
    try {
      AppLogger.info('🔐 Verifying App Store purchase');

      final url = isSandbox ? _appStoreSandboxVerifyUrl : _appStoreVerifyUrl;
      final requestBody = {
        'receipt-data': receiptData,
        'password': SecureFirebaseConfig.appStoreSharedSecret,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as int?;

        // status: 0 = valid, 21000+ = various errors
        if (status == 0) {
          AppLogger.info('✅ App Store purchase verified');
          return true;
        } else {
          AppLogger.warning('⚠️ App Store purchase not valid: status=$status');
          return false;
        }
      } else {
        AppLogger.error(
          '❌ App Store verification error: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Error verifying App Store purchase: $e');
      return false;
    }
  }

  /// Get Google access token using service account
  static Future<String?> _getGoogleAccessToken() async {
    try {
      // This is a simplified implementation
      // In production, you should use proper JWT signing and token caching
      // For now, we'll use a basic approach that works for development

      const serviceAccount = SecureFirebaseConfig.googlePlayServiceAccount;
      final clientEmail = serviceAccount['client_email'] as String?;
      final privateKey = serviceAccount['private_key'] as String?;

      if (clientEmail == null || privateKey == null) {
        AppLogger.error('❌ Service account credentials not found');
        return null;
      }

      // Create JWT for service account authentication
      final jwt = await _createServiceAccountJWT(clientEmail, privateKey);

      // Exchange JWT for access token
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': jwt,
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData =
            json.decode(tokenResponse.body) as Map<String, dynamic>;
        final accessToken = tokenData['access_token'] as String?;
        return accessToken;
      } else {
        AppLogger.error('❌ Failed to get access token: ${tokenResponse.body}');
        return null;
      }
    } catch (e) {
      AppLogger.error('❌ Error getting Google access token: $e');
      return null;
    }
  }

  /// Create JWT for service account authentication
  static Future<String> _createServiceAccountJWT(
    String clientEmail,
    String privateKey,
  ) async {
    try {
      // Create JWT header
      final header = {'alg': 'RS256', 'typ': 'JWT'};

      // Create JWT payload
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = {
        'iss': clientEmail,
        'scope': 'https://www.googleapis.com/auth/androidpublisher',
        'aud': 'https://oauth2.googleapis.com/token',
        'exp': now + 3600, // 1 hour from now
        'iat': now,
      };

      // Base64 encode header and payload
      final headerEncoded = base64Url
          .encode(utf8.encode(json.encode(header)))
          .replaceAll('=', '');
      final payloadEncoded = base64Url
          .encode(utf8.encode(json.encode(payload)))
          .replaceAll('=', '');

      // For now, return a placeholder JWT
      // TODO: Implement proper RS256 signing with crypto library
      AppLogger.warning(
        '⚠️ Using placeholder JWT - implement proper RS256 signing for production',
      );

      // This is a temporary implementation - in production you need:
      // 1. Parse the private key (PKCS#8 format)
      // 2. Use crypto library to sign with RS256
      // 3. Return properly signed JWT

      return '$headerEncoded.$payloadEncoded.placeholder_signature';
    } catch (e) {
      AppLogger.error('❌ Error creating JWT: $e');
      return 'PLACEHOLDER_JWT_TOKEN';
    }
  }
}
