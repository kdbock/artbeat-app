import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/ticket_purchase.dart';
import '../models/artbeat_event.dart';
import '../services/event_service.dart';
import '../utils/event_utils.dart';
import '../widgets/qr_code_ticket_widget.dart';

/// Screen for displaying user's purchased tickets
class MyTicketsScreen extends StatefulWidget {
  final String userId;

  const MyTicketsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with TickerProviderStateMixin {
  final EventService _eventService = EventService();

  List<TicketPurchase> _allTickets = [];
  List<TicketPurchase> _filteredTickets = [];
  Map<String, ArtbeatEvent> _eventCache = {};
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;
  int _currentTabIndex = 0;

  final List<String> _filterTabs = ['All', 'Upcoming', 'Past'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterTabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        _applyFilters();
      }
    });
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tickets = await _eventService.getUserTicketPurchases(widget.userId);

      // Load event details for each ticket
      final eventIds = tickets.map((t) => t.eventId).toSet();
      final events = <String, ArtbeatEvent>{};

      for (final eventId in eventIds) {
        try {
          final event = await _eventService.getEvent(eventId);
          if (event != null) {
            events[eventId] = event;
          }
        } on Exception {
          // Continue loading other events if one fails
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _allTickets = tickets;
          _eventCache = events;
          _isLoading = false;
        });
        _applyFilters();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<TicketPurchase> filtered = List.from(_allTickets);
    final now = DateTime.now();

    // Apply tab filter
    switch (_currentTabIndex) {
      case 1: // Upcoming
        filtered = filtered.where((ticket) {
          final event = _eventCache[ticket.eventId];
          return event != null && event.dateTime.isAfter(now);
        }).toList();
        break;
      case 2: // Past
        filtered = filtered.where((ticket) {
          final event = _eventCache[ticket.eventId];
          return event != null && event.dateTime.isBefore(now);
        }).toList();
        break;
    }

    // Sort by event date (upcoming first, then by date)
    filtered.sort((a, b) {
      final eventA = _eventCache[a.eventId];
      final eventB = _eventCache[b.eventId];

      if (eventA == null || eventB == null) return 0;

      final nowTime = DateTime.now();
      final aIsUpcoming = eventA.dateTime.isAfter(nowTime);
      final bIsUpcoming = eventB.dateTime.isAfter(nowTime);

      if (aIsUpcoming && !bIsUpcoming) return -1;
      if (!aIsUpcoming && bIsUpcoming) return 1;

      return eventA.dateTime.compareTo(eventB.dateTime);
    });

    setState(() {
      _filteredTickets = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 3, // Events tab
      child: Scaffold(
        appBar: const UniversalHeader(
          title: 'My Tickets',
          showLogo: false,
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
          child: Column(
            children: [
              // Tab bar below header
              Container(
                decoration: BoxDecoration(
                  color: ArtbeatColors.primaryPurple,
                  boxShadow: [
                    BoxShadow(
                      color: ArtbeatColors.primaryPurple.withAlpha(51),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: _filterTabs.map((tab) => Tab(text: tab)).toList(),
                  indicatorColor: ArtbeatColors.accentYellow,
                  labelColor: ArtbeatColors.textWhite,
                  unselectedLabelColor: ArtbeatColors.textWhite.withAlpha(179),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_filteredTickets.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTickets.length,
        itemBuilder: (context, index) {
          final ticket = _filteredTickets[index];
          final event = _eventCache[ticket.eventId];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTicketCard(ticket, event),
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(TicketPurchase ticket, ArtbeatEvent? event) {
    if (event == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Event not found for ticket ${ticket.id}'),
        ),
      );
    }

    final isUpcoming = event.dateTime.isAfter(DateTime.now());

    return Card(
      child: InkWell(
        onTap: () => _showTicketDetails(ticket, event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildTicketStatusBadge(ticket, isUpcoming),
                ],
              ),

              const SizedBox(height: 8),

              // Event date and time
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    EventUtils.formatEventDateTime(event.dateTime),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Location
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Ticket details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity: ${ticket.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: ${ticket.formattedAmount}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUpcoming && ticket.isActive)
                      Icon(
                        Icons.qr_code,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                  ],
                ),
              ),

              // Action buttons for upcoming events
              if (isUpcoming && ticket.isActive) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showQRCode(ticket, event),
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Show QR Code'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (event.canRefund)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _requestRefund(ticket, event),
                          icon: const Icon(Icons.money_off),
                          label: const Text('Request Refund'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketStatusBadge(TicketPurchase ticket, bool isUpcoming) {
    String text;
    Color color;

    if (ticket.isRefunded) {
      text = 'Refunded';
      color = Colors.orange;
    } else if (!isUpcoming) {
      text = 'Past Event';
      color = Colors.grey;
    } else if (ticket.isActive) {
      text = 'Active';
      color = Colors.green;
    } else {
      text = ticket.status.displayName;
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load tickets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTickets,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;

    switch (_currentTabIndex) {
      case 1: // Upcoming
        message = 'No upcoming events';
        subtitle = 'Your future event tickets will appear here';
        break;
      case 2: // Past
        message = 'No past events';
        subtitle = 'Your previous event tickets will appear here';
        break;
      default:
        message = 'No tickets found';
        subtitle = 'Purchase tickets for events to see them here';
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showTicketDetails(TicketPurchase ticket, ArtbeatEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Ticket details
                  Text(
                    'Ticket Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  _buildDetailRow('Event', event.title),
                  _buildDetailRow(
                      'Date', EventUtils.formatEventDateTime(event.dateTime)),
                  _buildDetailRow('Location', event.location),
                  _buildDetailRow('Quantity', ticket.quantity.toString()),
                  _buildDetailRow('Total Paid', ticket.formattedAmount),
                  _buildDetailRow(
                      'Purchase Date',
                      DateFormat('MMM d, y \'at\' h:mm a')
                          .format(ticket.purchaseDate)),
                  _buildDetailRow('Confirmation ID', ticket.id),
                  _buildDetailRow('Status', ticket.status.displayName),

                  if (ticket.refundDate != null)
                    _buildDetailRow(
                        'Refund Date',
                        DateFormat('MMM d, y \'at\' h:mm a')
                            .format(ticket.refundDate!)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showQRCode(TicketPurchase ticket, ArtbeatEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeTicketWidget(
          ticket: ticket,
          event: event,
        ),
      ),
    );
  }

  void _requestRefund(TicketPurchase ticket, ArtbeatEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Are you sure you want to request a refund for this ticket?'),
            const SizedBox(height: 16),
            Text('Refund amount: ${ticket.formattedAmount}'),
            const SizedBox(height: 8),
            Text(
              'Refund policy: ${event.refundPolicy.terms}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processRefund(ticket);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Request Refund'),
          ),
        ],
      ),
    );
  }

  Future<void> _processRefund(TicketPurchase ticket) async {
    try {
      // TODO: Process refund with payment provider
      await _eventService.refundTicketPurchase(ticket.id, 'mock_refund_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _loadTickets(); // Refresh the list
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process refund: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
