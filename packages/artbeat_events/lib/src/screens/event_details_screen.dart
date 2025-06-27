import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:share_plus/share_plus.dart';
import '../models/artbeat_event.dart';
import '../models/ticket_type.dart';
import '../services/event_service.dart';
import '../services/calendar_integration_service.dart';
import '../services/event_notification_service.dart';
import '../widgets/ticket_purchase_sheet.dart';
import '../utils/event_utils.dart';

/// Screen for displaying detailed event information
class EventDetailsScreen extends StatefulWidget {
  final ArtbeatEvent event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final EventService _eventService = EventService();
  final CalendarIntegrationService _calendarService =
      CalendarIntegrationService();
  final EventNotificationService _notificationService =
      EventNotificationService();

  late ArtbeatEvent _event;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _ticketsSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 3, // Events tab
      child: Scaffold(
        appBar: UniversalHeader(
          title: _event.title,
          showLogo: false,
          actions: [
            IconButton(
              onPressed: _shareEvent,
              icon: const Icon(Icons.share),
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'add_to_calendar',
                  child: ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text('Add to Calendar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'set_reminder',
                  child: ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text('Set Reminder'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    leading: Icon(Icons.flag),
                    title: Text('Report Event'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ArtbeatColors.primaryPurple.withAlpha(25),
                ArtbeatColors.backgroundPrimary,
                ArtbeatColors.primaryGreen.withAlpha(25),
              ],
            ),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventBanner(),
                _buildEventHeader(),
                _buildEventInfo(),
                _buildEventDescription(),
                _buildTicketTypes(),
                _buildEventTags(),
                _buildRefundPolicy(),
                _buildContactInfo(),
                const SizedBox(height: 100), // Space for floating action button
              ],
            ),
          ),
        ),
        floatingActionButton: _buildActionButtons(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildEventBanner() {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: _event.eventBannerUrl.isNotEmpty
          ? Image.network(
              _event.eventBannerUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholderBanner(),
            )
          : _buildPlaceholderBanner(),
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Event Banner',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _event.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor()),
                ),
                child: Text(
                  EventUtils.getEventStatus(_event),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                EventUtils.getTimeUntilEvent(_event.dateTime),
                style: const TextStyle(
                  color: ArtbeatColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtbeatColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtbeatColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today,
            'Date',
            EventUtils.formatEventDate(_event.dateTime),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.access_time,
            'Time',
            EventUtils.formatEventTime(_event.dateTime),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.location_on,
            'Location',
            _event.location,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.people,
            'Capacity',
            '${_event.attendeeIds.length} / ${_event.maxAttendees} attendees',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: ArtbeatColors.primaryPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: ArtbeatColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventDescription() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This Event',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _event.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketTypes() {
    if (_event.ticketTypes.isEmpty) return const SizedBox.shrink();

    return Padding(
      key: _ticketsSectionKey,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tickets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._event.ticketTypes.map(_buildTicketTypeCard),
        ],
      ),
    );
  }

  Widget _buildTicketTypeCard(TicketType ticket) {
    final isAvailable = ticket.isAvailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (ticket.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          ticket.description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ticket.formattedPrice,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '${ticket.remainingQuantity} left',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Benefits for VIP tickets
            if (ticket.benefits.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Includes:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              ...ticket.benefits.map((benefit) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            benefit,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isAvailable ? () => _showTicketPurchaseSheet(ticket) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAvailable ? null : Colors.grey.shade300,
                ),
                child: Text(
                  isAvailable ? 'Select Tickets' : 'Sold Out',
                  style: TextStyle(
                    color: isAvailable ? null : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTags() {
    if (_event.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _event.tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundPolicy() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.policy, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Refund Policy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _event.refundPolicy.fullDescription,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildContactRow(Icons.email, _event.contactEmail),
              if (_event.contactPhone != null &&
                  _event.contactPhone!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildContactRow(Icons.phone, _event.contactPhone!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton.extended(
          onPressed: _showAllTicketTypes,
          heroTag: 'tickets',
          icon: const Icon(Icons.confirmation_number),
          label: const Text('Get Tickets'),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    final status = EventUtils.getEventStatus(_event);
    switch (status) {
      case 'Ended':
        return Colors.grey;
      case 'Sold Out':
        return Colors.red;
      case 'Almost Full':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void _shareEvent() {
    final eventUrl = 'https://artbeat.app/events/${_event.id}';
    SharePlus.instance.share(
      ShareParams(text: 'Check out this event on ARTbeat! $eventUrl'),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'add_to_calendar':
        _addToCalendar();
        break;
      case 'set_reminder':
        _setReminder();
        break;
      case 'report':
        _reportEvent();
        break;
    }
  }

  Future<void> _addToCalendar() async {
    try {
      final success = await _calendarService.addEventToCalendar(_event);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Event added to calendar!'
                  : 'Failed to add event to calendar',
            ),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _setReminder() async {
    try {
      await _notificationService.scheduleEventReminders(_event);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder set!')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting reminder: $e')),
        );
      }
    }
  }

  void _reportEvent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Event'),
        content: const Text('Are you sure you want to report this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event reported')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showTicketPurchaseSheet(TicketType ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TicketPurchaseSheet(
        event: _event,
        ticketType: ticket,
        onPurchaseComplete: () {
          Navigator.pop(context);
          _refreshEvent();
        },
      ),
    );
  }

  void _showAllTicketTypes() {
    if (_event.ticketTypes.length == 1) {
      _showTicketPurchaseSheet(_event.ticketTypes.first);
    } else {
      // Scroll to tickets section
      final context = _ticketsSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _refreshEvent() async {
    try {
      final updatedEvent = await _eventService.getEvent(_event.id);
      if (updatedEvent != null && mounted) {
        setState(() {
          _event = updatedEvent;
        });
      }
    } on Exception {
      // Handle error silently or show a subtle message
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
