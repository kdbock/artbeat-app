import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/artbeat_event.dart';
import '../services/event_service.dart';
import 'event_details_screen.dart';

/// Wrapper screen that loads an event by ID and displays the EventDetailsScreen
class EventDetailsWrapper extends StatefulWidget {
  final String eventId;

  const EventDetailsWrapper({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailsWrapper> createState() => _EventDetailsWrapperState();
}

class _EventDetailsWrapperState extends State<EventDetailsWrapper> {
  final EventService _eventService = EventService();
  ArtbeatEvent? _event;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final event = await _eventService.getEvent(widget.eventId);
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load event: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MainLayout(
        currentIndex: 3, // Events tab
        child: Scaffold(
          appBar: UniversalHeader(
            title: 'Loading Event...',
            showLogo: false,
          ),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_error != null) {
      return MainLayout(
        currentIndex: 3, // Events tab
        child: Scaffold(
          appBar: const UniversalHeader(
            title: 'Event Not Found',
            showLogo: false,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_event == null) {
      return MainLayout(
        currentIndex: 3, // Events tab
        child: Scaffold(
          appBar: const UniversalHeader(
            title: 'Event Not Found',
            showLogo: false,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Event not found or no longer available',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return EventDetailsScreen(event: _event!);
  }
}
