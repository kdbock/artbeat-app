import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service class to handle event-related operations
class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get currently logged-in user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get event by ID
  Future<EventModel> getEventById(String eventId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final doc = await _firestore.collection('events').doc(eventId).get();

      if (!doc.exists) {
        throw Exception('Event not found');
      }

      final event = EventModel.fromFirestore(doc);

      // Check if user has permission to view this event
      if (!event.isPublic &&
          event.artistId != userId &&
          !event.attendeeIds.contains(userId)) {
        throw Exception('Permission denied');
      }

      return event;
    } catch (e) {
      throw Exception('Failed to fetch event: $e');
    }
  }

  /// Get local events for the current user
  Future<List<EventModel>> getLocalEvents() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('events')
          .where('isPublic', isEqualTo: true)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('startDate', descending: false)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch local events: $e');
    }
  }

  /// Create a new event
  Future<String> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    required String location,
    required bool isPublic,
    File? imageFile,
  }) async {
    final artistId = getCurrentUserId();
    if (artistId == null) {
      throw Exception('User not authenticated');
    }

    // Validate dates
    if (endDate != null && endDate.isBefore(startDate)) {
      throw Exception('End date cannot be before start date');
    }

    if (startDate.isBefore(DateTime.now())) {
      throw Exception('Start date cannot be in the past');
    }

    try {
      String? imageUrl;
      if (imageFile != null) {
        // Upload image to Firebase Storage
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final storageRef =
            _storage.ref().child('event_images/$artistId/$fileName');
        await storageRef.putFile(imageFile);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Create event document
      final eventRef = await _firestore.collection('events').add({
        'title': title,
        'description': description,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'location': location,
        'imageUrl': imageUrl,
        'artistId': artistId,
        'isPublic': isPublic,
        'attendeeIds': [artistId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return eventRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  /// Update an existing event
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    required String location,
    required bool isPublic,
    File? imageFile,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Verify event exists and user has permission
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }
      if (eventDoc.get('artistId') != userId) {
        throw Exception('Permission denied');
      }

      // Validate dates
      if (endDate != null && endDate.isBefore(startDate)) {
        throw Exception('End date cannot be before start date');
      }

      String? imageUrl = eventDoc.get('imageUrl');
      if (imageFile != null) {
        // Upload new image
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final storageRef =
            _storage.ref().child('event_images/$userId/$fileName');
        await storageRef.putFile(imageFile);
        imageUrl = await storageRef.getDownloadURL();

        // Delete old image if it exists
        final oldImageUrl = eventDoc.get('imageUrl') as String?;
        if (oldImageUrl != null) {
          try {
            await _storage.refFromURL(oldImageUrl).delete();
          } catch (e) {
            debugPrint('Failed to delete old image: $e');
          }
        }
      }

      // Update event document
      await _firestore.collection('events').doc(eventId).update({
        'title': title,
        'description': description,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'location': location,
        'imageUrl': imageUrl,
        'isPublic': isPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }
}
