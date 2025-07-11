import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artbeat_event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import '../screens/event_details_screen.dart';
import '../screens/create_event_screen.dart';

enum EventListMode { all, myEvents, myTickets }

/// Screen for displaying a list of events with filtering and search
class EventsListScreen extends StatefulWidget {
  final String? title;
  final String? artistId; // Filter by specific artist
  final List<String>? tags; // Filter by tags
  final bool showCreateButton;
  final EventListMode mode;
  final bool showBackButton;

  const EventsListScreen({
    super.key,
    this.title,
    this.artistId,
    this.tags,
    this.showCreateButton = false,
    this.mode = EventListMode.all,
    this.showBackButton = true,
  });

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen>
    with TickerProviderStateMixin {
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  List<ArtbeatEvent> _allEvents = [];
  List<ArtbeatEvent> _filteredEvents = [];
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;
  int _currentTabIndex = 0;

  final List<String> _filterTabs = ['All', 'Upcoming', 'Today', 'This Week'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterTabs.length, vsync: this);
    _loadEvents();
  }

  Future<void> _refreshEvents() async {
    await _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final events = await _eventService.getEvents(
        artistId: widget.artistId,
        tags: widget.tags,
        onlyMine: widget.mode == EventListMode.myEvents,
        onlyMyTickets: widget.mode == EventListMode.myTickets,
      );

      if (mounted) {
        setState(() {
          _allEvents = events;
          _filterEvents();
          _isLoading = false;
          _error = null;
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.code == 'permission-denied'
              ? 'You don\'t have permission to view these events. Please sign in first.'
              : 'Failed to load events: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'An unexpected error occurred while loading events. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _filterEvents() {
    var filtered = List<ArtbeatEvent>.from(_allEvents);

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((event) => event.category == _selectedCategory)
          .toList();
    }

    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((event) =>
              event.title.toLowerCase().contains(searchQuery) ||
              event.description.toLowerCase().contains(searchQuery))
          .toList();
    }

    // Apply tab filter
    switch (_currentTabIndex) {
      case 1: // Upcoming
        filtered = filtered
            .where((event) => event.dateTime.isAfter(DateTime.now()))
            .toList();
        break;
      case 2: // Today
        final now = DateTime.now();
        filtered = filtered
            .where((event) =>
                event.dateTime.year == now.year &&
                event.dateTime.month == now.month &&
                event.dateTime.day == now.day)
            .toList();
        break;
      case 3: // This Week
        final now = DateTime.now();
        final weekEnd = now.add(const Duration(days: 7));
        filtered = filtered
            .where((event) =>
                event.dateTime.isAfter(now) && event.dateTime.isBefore(weekEnd))
            .toList();
        break;
    }

    if (mounted) {
      setState(() {
        _filteredEvents = filtered;
      });
    }
  }

  void _onTabChanged(int index) {
    if (mounted) {
      setState(() {
        _currentTabIndex = index;
        _filterEvents();
      });
    }
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => _filterEvents(),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedCategory,
            items: [
              'All',
              'Art Show',
              'Workshop',
              'Exhibition',
              'Gallery Opening',
              'Other'
            ]
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                  _filterEvents();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    if (widget.title != null) return widget.title!;

    switch (widget.mode) {
      case EventListMode.all:
        return 'Events';
      case EventListMode.myEvents:
        return 'My Events';
      case EventListMode.myTickets:
        return 'My Tickets';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 3, // Events tab
      child: Scaffold(
        appBar: EnhancedUniversalHeader(
          title: _getTitle(),
          showLogo: false,
          showBackButton: widget.showBackButton,
          onBackPressed: () => Navigator.of(context).pop(),
          actions: [
            if (widget.showCreateButton)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateEventScreen(),
                      fullscreenDialog: true,
                    ),
                  );
                  if (result == true && mounted) {
                    _loadEvents();
                  }
                },
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No events found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.showCreateButton)
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                ),
                child: const Text('Create Event'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshEvents,
      child: Column(
        children: [
          _buildSearchAndFilter(),
          TabBar(
            controller: _tabController,
            tabs: _filterTabs.map((tab) => Tab(text: tab)).toList(),
            onTap: _onTabChanged,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredEvents.length,
              itemBuilder: (context, index) {
                final event = _filteredEvents[index];
                return EventCard(
                  event: event,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailsScreen(eventId: event.id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
