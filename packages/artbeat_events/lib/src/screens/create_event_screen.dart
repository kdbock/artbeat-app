import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/artbeat_event.dart';
import '../forms/event_form_builder.dart';
import '../services/event_service.dart';
import '../services/event_notification_service.dart';

/// Screen for creating new events
class CreateEventScreen extends StatefulWidget {
  final ArtbeatEvent? editEvent; // If editing an existing event

  const CreateEventScreen({
    super.key,
    this.editEvent,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final EventService _eventService = EventService();
  final EventNotificationService _notificationService =
      EventNotificationService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 3, // Events tab
      child: PopScope(
        canPop: !_isLoading,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _isLoading) {
            _showUnsavedChangesDialog();
          }
        },
        child: Stack(
          children: [
            EventFormBuilder(
              initialEvent: widget.editEvent,
              onEventCreated: _handleEventCreated,
              onCancel: () => Navigator.pop(context),
              useUniversalHeader:
                  true, // Tell the form builder to use universal header
            ),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Creating event...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEventCreated(ArtbeatEvent event) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      String eventId;

      if (widget.editEvent != null) {
        // Update existing event
        await _eventService.updateEvent(event);
        eventId = event.id;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new event
        eventId = await _eventService.createEvent(event);

        // Schedule event reminders if enabled
        if (event.reminderEnabled) {
          final updatedEvent = event.copyWith(id: eventId);
          await _notificationService.scheduleEventReminders(updatedEvent);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Show success dialog with options
      if (mounted) {
        _showSuccessDialog(eventId, widget.editEvent != null);
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog(String eventId, bool isEdit) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isEdit ? '✅ Event Updated!' : '✅ Event Created!',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit
                  ? 'Your event has been successfully updated.'
                  : 'Your event has been successfully created and is now live!',
            ),
            const SizedBox(height: 16),
            if (!isEdit) ...[
              const Text('What would you like to do next?'),
              const SizedBox(height: 16),
            ],
          ],
        ),
        actions: [
          if (!isEdit) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
                _shareEvent(eventId);
              },
              child: const Text('Share Event'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
                _viewEvent(eventId);
              },
              child: const Text('View Event'),
            ),
          ],
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Error'),
        content: Text('Failed to save event: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog only
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _shareEvent(String eventId) {
    // TODO: Implement event sharing
    // This could open a share sheet or navigate to a sharing screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share event: $eventId')),
    );
  }

  void _viewEvent(String eventId) {
    // TODO: Navigate to event details screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => EventDetailsScreen(eventId: eventId),
    //   ),
    // );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View event: $eventId')),
    );
  }
}
