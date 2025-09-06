import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/artbeat_event.dart';

/// Bulk management service for event operations
/// Handles batch operations on multiple events for efficiency
class EventBulkManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Bulk update multiple events with the same changes
  Future<void> bulkUpdateEvents(
    List<String> eventIds,
    Map<String, dynamic> updates,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (eventIds.isEmpty) {
      throw Exception('No events selected for update');
    }

    if (eventIds.length > 500) {
      throw Exception('Cannot update more than 500 events at once');
    }

    try {
      // Validate user permissions for each event
      await _validateBulkPermissions(eventIds, user.uid);

      // Add metadata to updates
      final enrichedUpdates = Map<String, dynamic>.from(updates);
      enrichedUpdates.addAll({
        'lastModified': FieldValue.serverTimestamp(),
        'modifiedBy': user.uid,
        'bulkOperation': true,
      });

      // Process in batches to avoid Firestore limits (500 operations per batch)
      final batchSize = 400; // Leave room for safety
      for (int i = 0; i < eventIds.length; i += batchSize) {
        final batch = _firestore.batch();
        final batchEventIds = eventIds.skip(i).take(batchSize);

        for (final eventId in batchEventIds) {
          final eventRef = _firestore.collection('events').doc(eventId);
          batch.update(eventRef, enrichedUpdates);
        }

        await batch.commit();
        _logger.i(
          'Updated batch ${(i ~/ batchSize) + 1} of ${(eventIds.length / batchSize).ceil()}',
        );
      }

      // Log bulk operation
      await _logBulkOperation('bulk_update', eventIds, updates);

      _logger.i('Successfully updated ${eventIds.length} events');
    } on FirebaseException catch (e) {
      _logger.e('Firebase error in bulk update: ${e.message}', error: e);
      rethrow;
    } catch (e) {
      _logger.e('Error in bulk update: $e', error: e);
      rethrow;
    }
  }

  /// Bulk delete multiple events
  Future<void> bulkDeleteEvents(List<String> eventIds) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (eventIds.isEmpty) {
      throw Exception('No events selected for deletion');
    }

    if (eventIds.length > 500) {
      throw Exception('Cannot delete more than 500 events at once');
    }

    try {
      // Validate user permissions for each event
      await _validateBulkPermissions(eventIds, user.uid);

      // Check for events with active ticket purchases
      final eventsWithPurchases = await _checkForActiveTicketPurchases(
        eventIds,
      );
      if (eventsWithPurchases.isNotEmpty) {
        throw Exception(
          'Cannot delete events with active ticket purchases: ${eventsWithPurchases.join(", ")}',
        );
      }

      // Process in batches
      final batchSize = 400;
      for (int i = 0; i < eventIds.length; i += batchSize) {
        final batch = _firestore.batch();
        final batchEventIds = eventIds.skip(i).take(batchSize);

        for (final eventId in batchEventIds) {
          final eventRef = _firestore.collection('events').doc(eventId);
          batch.delete(eventRef);

          // Also delete related data
          batch.delete(_firestore.collection('event_analytics').doc(eventId));
        }

        await batch.commit();
        _logger.i(
          'Deleted batch ${(i ~/ batchSize) + 1} of ${(eventIds.length / batchSize).ceil()}',
        );
      }

      // Clean up related subcollections
      await _cleanupRelatedData(eventIds);

      // Log bulk operation
      await _logBulkOperation('bulk_delete', eventIds, {});

      _logger.i('Successfully deleted ${eventIds.length} events');
    } on FirebaseException catch (e) {
      _logger.e('Firebase error in bulk deletion: ${e.message}', error: e);
      rethrow;
    } catch (e) {
      _logger.e('Error in bulk deletion: $e', error: e);
      rethrow;
    }
  }

  /// Bulk status change for multiple events
  Future<void> bulkStatusChange(List<String> eventIds, String status) async {
    final validStatuses = [
      'active',
      'inactive',
      'cancelled',
      'postponed',
      'draft',
    ];
    if (!validStatuses.contains(status)) {
      throw Exception(
        'Invalid status: $status. Valid statuses: ${validStatuses.join(", ")}',
      );
    }

    final updates = <String, dynamic>{
      'status': status,
      'isActive': status == 'active',
    };

    // Add status-specific fields
    switch (status) {
      case 'cancelled':
        updates['cancelledAt'] = FieldValue.serverTimestamp();
        break;
      case 'postponed':
        updates['postponedAt'] = FieldValue.serverTimestamp();
        break;
      case 'active':
        updates['activatedAt'] = FieldValue.serverTimestamp();
        break;
    }

    await bulkUpdateEvents(eventIds, updates);
    _logger.i(
      'Successfully changed status to "$status" for ${eventIds.length} events',
    );
  }

  /// Bulk assign events to a category or tag
  Future<void> bulkAssignCategory(
    List<String> eventIds,
    String category, {
    List<String>? tags,
  }) async {
    final updates = <String, dynamic>{'category': category};

    if (tags != null && tags.isNotEmpty) {
      updates['tags'] = FieldValue.arrayUnion(tags);
    }

    await bulkUpdateEvents(eventIds, updates);
    _logger.i(
      'Successfully assigned category "$category" to ${eventIds.length} events',
    );
  }

  /// Bulk update event pricing
  Future<void> bulkUpdatePricing(
    List<String> eventIds,
    Map<String, dynamic> pricingUpdates,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Validate pricing structure
    if (!_isValidPricingStructure(pricingUpdates)) {
      throw Exception('Invalid pricing structure provided');
    }

    // Check if any events have existing purchases that might be affected
    final eventsWithPurchases = await _checkForActiveTicketPurchases(eventIds);
    if (eventsWithPurchases.isNotEmpty) {
      // For events with purchases, only allow specific pricing updates
      if (pricingUpdates.containsKey('ticketPrice') &&
          eventsWithPurchases.isNotEmpty) {
        throw Exception(
          'Cannot change ticket prices for events with existing purchases: ${eventsWithPurchases.join(", ")}',
        );
      }
    }

    await bulkUpdateEvents(eventIds, pricingUpdates);
    _logger.i('Successfully updated pricing for ${eventIds.length} events');
  }

  /// Get events that can be bulk managed by the current user
  Future<List<ArtbeatEvent>> getBulkManageableEvents({
    String? category,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      Query query = _firestore
          .collection('events')
          .where('artistId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);

      // Apply filters
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (startDate != null) {
        query = query.where(
          'dateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'dateTime',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs.map(ArtbeatEvent.fromFirestore).toList();
    } on FirebaseException catch (e) {
      _logger.e(
        'Firebase error getting bulk manageable events: ${e.message}',
        error: e,
      );
      return [];
    } on Exception catch (e) {
      _logger.e('Error getting bulk manageable events: $e', error: e);
      return [];
    }
  }

  /// Preview bulk operation impact
  Future<Map<String, dynamic>> previewBulkOperation(
    List<String> eventIds,
    String operationType,
    Map<String, dynamic>? changes,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get current event data
      final events = await _getEventsById(eventIds);
      final eventsWithPurchases = await _checkForActiveTicketPurchases(
        eventIds,
      );

      // Calculate impact
      final impact = <String, dynamic>{
        'totalEvents': eventIds.length,
        'operationType': operationType,
        'eventsFound': events.length,
        'eventsWithTicketPurchases': eventsWithPurchases.length,
        'warnings': <String>[],
        'blocked': <String>[],
        'previewedAt': FieldValue.serverTimestamp(),
      };

      // Add operation-specific warnings
      switch (operationType) {
        case 'delete':
          if (eventsWithPurchases.isNotEmpty) {
            impact['warnings'].add(
              '${eventsWithPurchases.length} events have ticket purchases and cannot be deleted',
            );
            impact['blocked'] = eventsWithPurchases;
          }
          break;
        case 'update':
          if (changes != null &&
              changes.containsKey('ticketPrice') &&
              eventsWithPurchases.isNotEmpty) {
            impact['warnings'].add(
              '${eventsWithPurchases.length} events have purchases and pricing cannot be changed',
            );
          }
          break;
      }

      // Check permissions
      final permissionIssues = await _checkBulkPermissionIssues(
        eventIds,
        user.uid,
      );
      if (permissionIssues.isNotEmpty) {
        impact['warnings'].add(
          '${permissionIssues.length} events cannot be modified due to permissions',
        );
        impact['blocked'].addAll(permissionIssues);
      }

      return impact;
    } on FirebaseException catch (e) {
      _logger.e(
        'Firebase error previewing bulk operation: ${e.message}',
        error: e,
      );
      return {'error': 'Firebase error: ${e.message}'};
    } on Exception catch (e) {
      _logger.e('Error previewing bulk operation: $e', error: e);
      return {'error': e.toString()};
    }
  }

  // Helper Methods

  /// Validate user has permissions to modify all specified events
  Future<void> _validateBulkPermissions(
    List<String> eventIds,
    String userId,
  ) async {
    // Get all events in smaller batches
    const batchSize = 10;
    for (int i = 0; i < eventIds.length; i += batchSize) {
      final batch = eventIds.skip(i).take(batchSize);

      final query = await _firestore
          .collection('events')
          .where(FieldPath.documentId, whereIn: batch.toList())
          .get();

      for (final doc in query.docs) {
        final event = ArtbeatEvent.fromFirestore(doc);
        if (event.artistId != userId) {
          throw Exception('Insufficient permissions for event: ${event.title}');
        }
      }
    }
  }

  /// Check which events have active ticket purchases
  Future<List<String>> _checkForActiveTicketPurchases(
    List<String> eventIds,
  ) async {
    final eventsWithPurchases = <String>[];

    // Check in batches
    const batchSize = 10;
    for (int i = 0; i < eventIds.length; i += batchSize) {
      final batch = eventIds.skip(i).take(batchSize);

      final purchasesQuery = await _firestore
          .collection('ticket_purchases')
          .where('eventId', whereIn: batch.toList())
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();

      final eventIdsWithPurchases = purchasesQuery.docs
          .map((doc) => doc.data()['eventId'] as String)
          .toSet();

      eventsWithPurchases.addAll(eventIdsWithPurchases);
    }

    return eventsWithPurchases;
  }

  /// Clean up related data after bulk deletion
  Future<void> _cleanupRelatedData(List<String> eventIds) async {
    // Clean up in parallel for efficiency
    final cleanupFutures = eventIds.map((eventId) async {
      // Clean up event flags
      final flagsQuery = await _firestore
          .collection('event_flags')
          .where('eventId', isEqualTo: eventId)
          .get();

      final batch = _firestore.batch();
      for (final flagDoc in flagsQuery.docs) {
        batch.delete(flagDoc.reference);
      }
      await batch.commit();
    });

    await Future.wait(cleanupFutures);
  }

  /// Log bulk operations for audit trail
  Future<void> _logBulkOperation(
    String operationType,
    List<String> eventIds,
    Map<String, dynamic> changes,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('bulk_operations_log').add({
        'operationType': operationType,
        'eventIds': eventIds,
        'eventCount': eventIds.length,
        'changes': changes,
        'performedBy': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      _logger.e(
        'Firebase error logging bulk operation: ${e.message}',
        error: e,
      );
      // Don't throw - logging failure shouldn't block the operation
    } on Exception catch (e) {
      _logger.e('Error logging bulk operation: $e', error: e);
      // Don't throw - logging failure shouldn't block the operation
    }
  }

  /// Validate pricing structure
  bool _isValidPricingStructure(Map<String, dynamic> pricing) {
    // Basic validation - extend as needed
    if (pricing.containsKey('ticketPrice')) {
      final price = pricing['ticketPrice'];
      if (price is! num || price < 0) return false;
    }

    return true;
  }

  /// Get events by IDs
  Future<List<ArtbeatEvent>> _getEventsById(List<String> eventIds) async {
    final events = <ArtbeatEvent>[];

    // Process in batches due to Firestore 'whereIn' limits
    const batchSize = 10;
    for (int i = 0; i < eventIds.length; i += batchSize) {
      final batch = eventIds.skip(i).take(batchSize);

      final query = await _firestore
          .collection('events')
          .where(FieldPath.documentId, whereIn: batch.toList())
          .get();

      events.addAll(query.docs.map(ArtbeatEvent.fromFirestore));
    }

    return events;
  }

  /// Check for permission issues without throwing
  Future<List<String>> _checkBulkPermissionIssues(
    List<String> eventIds,
    String userId,
  ) async {
    final blockedEvents = <String>[];

    try {
      const batchSize = 10;
      for (int i = 0; i < eventIds.length; i += batchSize) {
        final batch = eventIds.skip(i).take(batchSize);

        final query = await _firestore
            .collection('events')
            .where(FieldPath.documentId, whereIn: batch.toList())
            .get();

        for (final doc in query.docs) {
          final event = ArtbeatEvent.fromFirestore(doc);
          if (event.artistId != userId) {
            blockedEvents.add(event.id);
          }
        }
      }
    } on FirebaseException catch (e) {
      _logger.e('Firebase error checking permissions: ${e.message}', error: e);
    } on Exception catch (e) {
      _logger.e('Error checking permissions: $e', error: e);
    }

    return blockedEvents;
  }
}
