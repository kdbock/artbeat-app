import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A testable version of ImageModerationService with dependency injection
class TestableImageModerationService {
  final String apiKey;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client _httpClient;

  TestableImageModerationService({
    required this.apiKey,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required http.Client httpClient,
  })  : _firestore = firestore,
        _auth = auth,
        _httpClient = httpClient;

  // Check if image is appropriate using third-party API
  Future<Map<String, dynamic>> checkImage(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Call API
      final response = await _httpClient.post(
        Uri.parse('https://api.moderatecontent.com/moderate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Api-Key $apiKey',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;

        // Log the moderation result in Firestore
        await _logModerationResult(result);

        return result;
      } else {
        throw Exception('Failed to moderate image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in image moderation: $e');

      // Log error in Firestore
      await _logModerationError(e.toString());

      rethrow;
    }
  }

  // Log the moderation result in Firestore
  Future<void> _logModerationResult(Map<String, dynamic> result) async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        await _firestore.collection('moderation_logs').add({
          'userId': userId,
          'result': result,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completed',
        });
      }
    } catch (e) {
      debugPrint('Error logging moderation result: $e');
    }
  }

  // Log moderation error in Firestore
  Future<void> _logModerationError(String errorMessage) async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        await _firestore.collection('moderation_logs').add({
          'userId': userId,
          'error': errorMessage,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'error',
        });
      }
    } catch (e) {
      debugPrint('Error logging moderation error: $e');
    }
  }

  // Verify that artwork follows content guidelines
  Future<bool> verifyArtworkContent(String artworkId) async {
    try {
      final artworkDoc =
          await _firestore.collection('artwork').doc(artworkId).get();

      if (!artworkDoc.exists) {
        throw Exception('Artwork not found');
      }

      final data = artworkDoc.data() as Map<String, dynamic>;

      // Check if the artwork has already been verified
      if (data.containsKey('isVerified')) {
        return data['isVerified'] as bool;
      }

      // Mark the artwork as pending verification
      await _firestore
          .collection('artwork')
          .doc(artworkId)
          .update({'verificationStatus': 'pending'});

      return false;
    } catch (e) {
      debugPrint('Error verifying artwork content: $e');
      rethrow;
    }
  }
}
