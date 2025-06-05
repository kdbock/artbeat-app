import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_artist/src/models/event_model.dart';

/// Service class to handle event-related operations
class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get currently logged-in user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Create a new event
  Future<String> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required TimeOfDay startTime,
    TimeOfDay? endTime,
    required String location,
    required bool isPublic,
    File? imageFile,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Upload image if provided
    String imageUrl = '';
    if (imageFile != null) {
      imageUrl = await _uploadEventImage(imageFile);
    }

    // Create event in Firestore
    final docRef = await _firestore.collection('events').add({
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'startTimeMinutes': _timeOfDayToMinutes(startTime),
      if (endTime != null) 'endTimeMinutes': _timeOfDayToMinutes(endTime),
      'location': location,
      'imageUrl': imageUrl,
      'userId': userId,
      'isPublic': isPublic,
      'attendees': [userId], // Creator is automatically attending
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Update an existing event
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? location,
    bool? isPublic,
    File? imageFile,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get current event data to check ownership
    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    if (!eventDoc.exists) {
      throw Exception('Event not found');
    }

    final eventData = eventDoc.data()!;
    if (eventData['userId'] != userId) {
      throw Exception('You can only update your own events');
    }

    // Prepare update data
    final Map<String, dynamic> updateData = {};

    if (title != null) updateData['title'] = title;
    if (description != null) updateData['description'] = description;
    if (date != null) updateData['date'] = Timestamp.fromDate(date);
    if (startTime != null) {
      updateData['startTimeMinutes'] = _timeOfDayToMinutes(startTime);
    }
    if (endTime != null) {
      updateData['endTimeMinutes'] = _timeOfDayToMinutes(endTime);
    }
    if (location != null) updateData['location'] = location;
    if (isPublic != null) updateData['isPublic'] = isPublic;

    // Upload new image if provided
    if (imageFile != null) {
      final imageUrl = await _uploadEventImage(imageFile);
      updateData['imageUrl'] = imageUrl;
    }

    // Update the event
    await _firestore.collection('events').doc(eventId).update(updateData);
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get current event data to check ownership
    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    if (!eventDoc.exists) {
      throw Exception('Event not found');
    }

    final eventData = eventDoc.data()!;
    if (eventData['userId'] != userId) {
      throw Exception('You can only delete your own events');
    }

    // Delete the event
    await _firestore.collection('events').doc(eventId).delete();

    // Delete image if it exists
    final imageUrl = eventData['imageUrl'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(imageUrl).delete();
      } catch (e) {
        // Ignore errors when deleting images
        print('Error deleting image: $e');
      }
    }
  }

  /// RSVP to an event (attend or unattend)
  Future<void> toggleAttendance(String eventId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get current event data
    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    if (!eventDoc.exists) {
      throw Exception('Event not found');
    }

    final eventData = eventDoc.data()!;
    final List<String> attendees =
        List<String>.from(eventData['attendees'] ?? []);

    // Toggle attendance
    if (attendees.contains(userId)) {
      // User is already attending, so remove
      attendees.remove(userId);
    } else {
      // User is not attending, so add
      attendees.add(userId);
    }

    // Update the event
    await _firestore.collection('events').doc(eventId).update({
      'attendees': attendees,
    });
  }

  /// Get all events for a user's personal calendar
  Future<List<EventModel>> getUserEvents(String userId) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // We need to split this into two separate queries because of how Firestore works with compound queries
    // Query 1: Events where user is the creator
    final creatorEventsSnapshot = await _firestore
        .collection('events')
        .where('userId', isEqualTo: userId)
        .orderBy('date')
        .orderBy(FieldPath.documentId) // Add this to match the index
        .get();

    // Query 2: Events user is attending
    final attendingEventsSnapshot = await _firestore
        .collection('events')
        .where('attendees', arrayContains: userId)
        .orderBy('date')
        .orderBy(FieldPath.documentId) // Add this to match the index
        .get();

    // Combine results and remove duplicates
    final Map<String, EventModel> uniqueEvents = {};

    for (final doc in creatorEventsSnapshot.docs) {
      uniqueEvents[doc.id] = EventModel.fromFirestore(doc);
    }

    for (final doc in attendingEventsSnapshot.docs) {
      if (!uniqueEvents.containsKey(doc.id)) {
        uniqueEvents[doc.id] = EventModel.fromFirestore(doc);
      }
    }

    return uniqueEvents.values.toList();
  }

  /// Get community calendar events (public events)
  Future<List<EventModel>> getCommunityEvents(
      {DateTime? fromDate, DateTime? toDate}) async {
    Query query =
        _firestore.collection('events').where('isPublic', isEqualTo: true);

    if (fromDate != null && toDate != null) {
      // When both dates are specified, we need a composite index
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(toDate));
    } else if (fromDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
    } else if (toDate != null) {
      query =
          query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(toDate));
    }

    final snapshot = await query.orderBy('date').get();

    return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
  }

  /// Get events for a specific date
  Future<List<EventModel>> getEventsForDate(DateTime date) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Create timestamp for start and end of the selected date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Split this into separate queries to match our indexes
    // Query 1: Events where user is the creator for this date
    final creatorSnapshot = await _firestore
        .collection('events')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    // Query 2: Events user is attending for this date
    final attendingSnapshot = await _firestore
        .collection('events')
        .where('attendees', arrayContains: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    // Query 3: Public events for this date
    final publicSnapshot = await _firestore
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    // Combine results and remove duplicates
    final Map<String, EventModel> uniqueEvents = {};

    // Add events the user created
    for (final doc in creatorSnapshot.docs) {
      uniqueEvents[doc.id] = EventModel.fromFirestore(doc);
    }

    // Add events the user is attending (if not already added)
    for (final doc in attendingSnapshot.docs) {
      if (!uniqueEvents.containsKey(doc.id)) {
        uniqueEvents[doc.id] = EventModel.fromFirestore(doc);
      }
    }

    // Add public events (if not already added)
    for (final doc in publicSnapshot.docs) {
      if (!uniqueEvents.containsKey(doc.id)) {
        uniqueEvents[doc.id] = EventModel.fromFirestore(doc);
      }
    }

    return uniqueEvents.values.toList();
  }

  /// Get a specific event by ID
  Future<EventModel?> getEventById(String eventId) async {
    final doc = await _firestore.collection('events').doc(eventId).get();

    if (!doc.exists) {
      return null;
    }

    return EventModel.fromFirestore(doc);
  }

  /// Helper method to upload event image to Firebase Storage
  Future<String> _uploadEventImage(File imageFile) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId';
    final ref = _storage.ref().child('event_images/$fileName');

    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  /// Pick image from gallery or camera
  Future<File?> pickEventImage({required bool fromCamera}) async {
    final picker = ImagePicker();
    final source = fromCamera ? ImageSource.camera : ImageSource.gallery;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }

    return null;
  }

  /// Helper method to convert TimeOfDay to minutes since midnight
  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }
}
