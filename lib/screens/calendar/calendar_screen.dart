import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:artbeat/models/event_model.dart';
import 'package:artbeat/services/event_service.dart';
import 'package:intl/intl.dart';

/// Main calendar screen that displays events and allows date selection
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  late TabController _tabController;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<EventModel> _selectedEvents = [];
  bool _isLoading = false;
  bool _showOnlyCommunity = false;

  // Map to store events for specific dates
  Map<DateTime, List<EventModel>> _events = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _showOnlyCommunity = _tabController.index == 1;
        _updateSelectedEvents();
      });
    }
  }

  // Load both personal and community events
  Future<void> _loadEvents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = _eventService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get events for the current month
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      // Load personal events
      final personalEvents = await _eventService.getUserEvents(currentUserId);

      // Load community events
      final communityEvents = await _eventService.getCommunityEvents(
          fromDate: startOfMonth, toDate: endOfMonth);

      // Organize events by date
      final Map<DateTime, List<EventModel>> eventsMap = {};

      void addEventToMap(EventModel event) {
        final eventDate = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
        );

        if (eventsMap[eventDate] == null) {
          eventsMap[eventDate] = [];
        }

        // Check if event is already added (avoid duplicates)
        if (!eventsMap[eventDate]!.any((e) => e.id == event.id)) {
          eventsMap[eventDate]!.add(event);
        }
      }

      for (final event in personalEvents) {
        addEventToMap(event);
      }

      for (final event in communityEvents) {
        addEventToMap(event);
      }

      if (!mounted) return;
      setState(() {
        _events = eventsMap;
        _isLoading = false;
        _updateSelectedEvents();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading events: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update the events shown for the selected day
  void _updateSelectedEvents() {
    final selectedDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    final events = _events[selectedDate] ?? [];

    if (_showOnlyCommunity) {
      // Filter to show only public community events
      setState(() {
        _selectedEvents = events.where((event) => event.isPublic).toList();
      });
    } else {
      setState(() {
        _selectedEvents = events;
      });
    }
  }

  // Open event creation form for the selected day
  void _createEventForSelectedDay() {
    Navigator.pushNamed(
      context,
      '/calendar/create-event',
      arguments: {'selectedDate': _selectedDay},
    ).then((_) => _loadEvents()); // Reload events when returning from form
  }

  // View event details
  void _viewEventDetails(EventModel event) {
    Navigator.pushNamed(
      context,
      '/calendar/event-detail',
      arguments: {'eventId': event.id},
    ).then((_) => _loadEvents()); // Reload events when returning from details
  }

  // Show the create event form
  void _showCreateEventForm() {
    _createEventForSelectedDay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Calendar'),
            Tab(text: 'Community Events'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendar(),
                const Divider(),
                Expanded(child: _buildEventsList()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag:
            'calendar_fab', // Use heroTag property instead of wrapping with Hero
        onPressed: _createEventForSelectedDay,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      eventLoader: (day) {
        final eventDate = DateTime(day.year, day.month, day.day);
        return _showOnlyCommunity
            ? (_events[eventDate] ?? [])
                .where((event) => event.isPublic)
                .toList()
            : (_events[eventDate] ?? []);
      },
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _updateSelectedEvents();
          });
        }
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
        // Reload events when changing months
        if (_focusedDay.month != _selectedDay.month) {
          _loadEvents();
        }
      },
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    if (_selectedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No events for ${DateFormat.yMMMd().format(_selectedDay)}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _createEventForSelectedDay,
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _selectedEvents.length,
      itemBuilder: (context, index) {
        final event = _selectedEvents[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              backgroundImage: event.imageUrl.isNotEmpty
                  ? NetworkImage(event.imageUrl) as ImageProvider
                  : null,
              child: event.imageUrl.isEmpty ? const Icon(Icons.event) : null,
            ),
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event.startTime.format(context)} - ${event.location}',
                ),
                if (event.isPublic)
                  const Text(
                    '(Community Event)',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _viewEventDetails(event),
          ),
        );
      },
    );
  }
}
