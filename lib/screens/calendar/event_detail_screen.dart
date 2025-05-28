import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:artbeat/models/event_model.dart';
import 'package:artbeat/services/event_service.dart';
import 'package:artbeat/services/user_service.dart';

/// Screen to display event details
class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _eventService = EventService();
  final UserService _userService = UserService();

  bool _isLoading = true;
  bool _isAttending = false;
  bool _isCurrentUserEvent = false;
  EventModel? _event;
  String _creatorName = '';
  String _creatorImageUrl = '';

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final event = await _eventService.getEventById(widget.eventId);
      if (event == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event not found')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Get creator info
      final creatorId = event.userId;
      final creator = await _userService.getUserById(creatorId);

      final currentUserId = _eventService.getCurrentUserId();
      final isCurrentUserEvent =
          currentUserId != null && currentUserId == creatorId;
      final isAttending = event.attendees.contains(currentUserId);

      if (!mounted) return;

      String creatorName = 'Unknown User';
      String creatorImageUrl = '';

      creatorName = creator.fullName;
      creatorImageUrl = creator.profileImageUrl;
    
      setState(() {
        _event = event;
        _creatorName = creatorName;
        _creatorImageUrl = creatorImageUrl;
        _isCurrentUserEvent = isCurrentUserEvent;
        _isAttending = isAttending;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading event: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAttendance() async {
    if (_event == null) return;

    try {
      await _eventService.toggleAttendance(_event!.id);

      if (!mounted) return;
      setState(() {
        _isAttending = !_isAttending;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isAttending
              ? 'You are now attending'
              : 'You are no longer attending'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _editEvent() {
    if (_event == null) return;

    Navigator.pushNamed(
      context,
      '/calendar/edit-event',
      arguments: {
        'eventId': _event!.id,
        'selectedDate': _event!.date,
      },
    ).then((_) => _loadEvent()); // Reload event when returning from edit form
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    final dateString = DateFormat.yMMMMd().format(date);
    final timeString = time.format(context);
    return '$dateString at $timeString';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: Text('Event not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          if (_isCurrentUserEvent)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editEvent,
              tooltip: 'Edit Event',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEventImage(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventTitle(),
                  const SizedBox(height: 8),
                  _buildEventMeta(),
                  const SizedBox(height: 24),
                  _buildEventDescription(),
                  const SizedBox(height: 24),
                  _buildEventLocation(),
                  const SizedBox(height: 24),
                  _buildEventCreator(),
                  const SizedBox(height: 32),
                  _buildAttendeeCount(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !_isCurrentUserEvent ? _buildAttendButton() : null,
    );
  }

  Widget _buildEventImage() {
    return _event!.imageUrl.isNotEmpty
        ? Image.network(
            _event!.imageUrl,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (ctx, obj, st) => Container(
              height: 150,
              color: Colors.grey[300],
              child:
                  const Icon(Icons.broken_image, size: 80, color: Colors.grey),
            ),
          )
        : Container(
            height: 150,
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            child: Icon(
              Icons.event,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
          );
  }

  Widget _buildEventTitle() {
    return Text(
      _event!.title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildEventMeta() {
    final startTimeStr = _formatDateTime(_event!.date, _event!.startTime);
    final endTimeStr =
        _event!.endTime != null ? ' - ${_event!.endTime!.format(context)}' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$startTimeStr$endTimeStr',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_event!.isPublic)
          Chip(
            label: const Text('Community Event'),
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            avatar: Icon(
              Icons.people,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
      ],
    );
  }

  Widget _buildEventDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _event!.description,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildEventLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _event!.location,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventCreator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Created by',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              backgroundImage: _creatorImageUrl.isNotEmpty
                  ? NetworkImage(_creatorImageUrl) as ImageProvider
                  : null,
              backgroundColor: Colors.grey[200],
              radius: 20,
              child: _creatorImageUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Text(
              _creatorName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendeeCount() {
    final attendeeCount = _event!.attendees.length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$attendeeCount ${attendeeCount == 1 ? 'person' : 'people'} attending',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _toggleAttendance,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: _isAttending ? Colors.red[50] : null,
          ),
          child: Text(
            _isAttending ? 'CANCEL ATTENDANCE' : 'ATTEND THIS EVENT',
            style: TextStyle(
              fontSize: 16,
              color: _isAttending ? Colors.red : null,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
