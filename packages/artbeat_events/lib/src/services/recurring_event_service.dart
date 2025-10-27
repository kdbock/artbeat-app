import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/artbeat_event.dart';

/// Service for managing recurring events and generating event instances
class RecurringEventService {
  static const String _eventsCollection = 'events';
  static const int _maxRecurringInstances =
      52; // Maximum instances to generate (e.g., 1 year of weekly events)

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  /// Generate recurring event instances based on the parent event's recurrence pattern
  /// Returns the list of generated event IDs
  Future<List<String>> generateRecurringInstances(
    String parentEventId,
    ArtbeatEvent parentEvent,
  ) async {
    if (!parentEvent.isRecurring) {
      _logger.w('Event is not marked as recurring: $parentEventId');
      return [];
    }

    if (parentEvent.recurrencePattern == null) {
      _logger.w('No recurrence pattern specified for event: $parentEventId');
      return [];
    }

    try {
      final instances = _calculateEventInstances(parentEvent, parentEventId);
      final generatedIds = <String>[];

      // Create all instances in a batch
      final batch = _firestore.batch();

      for (final instance in instances) {
        final docRef = _firestore.collection(_eventsCollection).doc();
        batch.set(docRef, instance.toFirestore());
        generatedIds.add(docRef.id);
      }

      await batch.commit();

      _logger.i(
        'Generated ${instances.length} recurring event instances for parent: $parentEventId',
      );
      return generatedIds;
    } catch (e) {
      _logger.e('Error generating recurring event instances: $e');
      rethrow;
    }
  }

  /// Calculate all event instances based on recurrence pattern
  List<ArtbeatEvent> _calculateEventInstances(
    ArtbeatEvent parentEvent,
    String parentEventId,
  ) {
    final instances = <ArtbeatEvent>[];
    final pattern = parentEvent.recurrencePattern!;
    final interval = parentEvent.recurrenceInterval ?? 1;
    final endDate = parentEvent.recurrenceEndDate;

    DateTime currentDate = parentEvent.dateTime;
    int instanceCount = 0;

    // Generate instances until we hit the end date or max instances
    while (instanceCount < _maxRecurringInstances) {
      // Calculate next occurrence
      currentDate = _getNextOccurrence(currentDate, pattern, interval);

      // Check if we've exceeded the end date
      if (endDate != null && currentDate.isAfter(endDate)) {
        break;
      }

      // Create instance event
      final instance = parentEvent.copyWith(
        id: '', // Will be set by Firestore
        dateTime: currentDate,
        parentEventId: parentEventId,
        isRecurring: false, // Instances are not recurring themselves
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attendeeIds: [], // Each instance has its own attendees
      );

      instances.add(instance);
      instanceCount++;
    }

    return instances;
  }

  /// Calculate the next occurrence based on pattern and interval
  DateTime _getNextOccurrence(
    DateTime currentDate,
    String pattern,
    int interval,
  ) {
    switch (pattern.toLowerCase()) {
      case 'daily':
        return currentDate.add(Duration(days: interval));

      case 'weekly':
        return currentDate.add(Duration(days: 7 * interval));

      case 'monthly':
        return DateTime(
          currentDate.year,
          currentDate.month + interval,
          currentDate.day,
          currentDate.hour,
          currentDate.minute,
        );

      case 'custom':
        // For custom patterns, default to weekly
        return currentDate.add(Duration(days: 7 * interval));

      default:
        _logger.w('Unknown recurrence pattern: $pattern, defaulting to weekly');
        return currentDate.add(Duration(days: 7 * interval));
    }
  }

  /// Delete all instances of a recurring event
  Future<void> deleteRecurringInstances(String parentEventId) async {
    try {
      final query = await _firestore
          .collection(_eventsCollection)
          .where('parentEventId', isEqualTo: parentEventId)
          .get();

      if (query.docs.isEmpty) {
        _logger.i('No instances found for parent event: $parentEventId');
        return;
      }

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _logger.i(
        'Deleted ${query.docs.length} instances for parent event: $parentEventId',
      );
    } catch (e) {
      _logger.e('Error deleting recurring event instances: $e');
      rethrow;
    }
  }

  /// Update all instances of a recurring event with new data
  /// This is useful when the parent event is updated
  Future<void> updateRecurringInstances(
    String parentEventId,
    ArtbeatEvent updatedParentEvent,
  ) async {
    try {
      final query = await _firestore
          .collection(_eventsCollection)
          .where('parentEventId', isEqualTo: parentEventId)
          .get();

      if (query.docs.isEmpty) {
        _logger.i('No instances found for parent event: $parentEventId');
        return;
      }

      final batch = _firestore.batch();

      for (final doc in query.docs) {
        final instance = ArtbeatEvent.fromFirestore(doc);

        // Update instance with parent's data but keep instance-specific fields
        final updatedInstance = updatedParentEvent.copyWith(
          id: instance.id,
          dateTime: instance.dateTime, // Keep original instance date
          parentEventId: parentEventId,
          isRecurring: false,
          attendeeIds: instance.attendeeIds, // Keep instance attendees
          viewCount: instance.viewCount,
          likeCount: instance.likeCount,
          shareCount: instance.shareCount,
          saveCount: instance.saveCount,
          createdAt: instance.createdAt,
          updatedAt: DateTime.now(),
        );

        batch.update(doc.reference, updatedInstance.toFirestore());
      }

      await batch.commit();
      _logger.i(
        'Updated ${query.docs.length} instances for parent event: $parentEventId',
      );
    } catch (e) {
      _logger.e('Error updating recurring event instances: $e');
      rethrow;
    }
  }

  /// Get all instances of a recurring event
  Future<List<ArtbeatEvent>> getRecurringInstances(String parentEventId) async {
    try {
      final query = await _firestore
          .collection(_eventsCollection)
          .where('parentEventId', isEqualTo: parentEventId)
          .orderBy('dateTime', descending: false)
          .get();

      return query.docs.map(ArtbeatEvent.fromFirestore).toList();
    } catch (e) {
      _logger.e('Error getting recurring event instances: $e');
      rethrow;
    }
  }
}
