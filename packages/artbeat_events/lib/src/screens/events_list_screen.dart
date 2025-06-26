import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/artbeat_event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import '../screens/event_details_screen.dart';
import '../screens/create_event_screen.dart';
import '../utils/event_utils.dart';

/// Screen for displaying a list of events with filtering and search
class EventsListScreen extends StatefulWidget {
  final String? title;
  final String? artistId; // Filter by specific artist
  final List<String>? tags; // Filter by tags
  final bool showCreateButton;

  const EventsListScreen({
    super.key,
    this.title,
    this.artistId,
    this.tags,
    this.showCreateButton = false,
  });

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen>
    with TickerProviderStateMixin {
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();

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
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        _applyFilters();
      }
    });
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      List<ArtbeatEvent> events;

      if (widget.artistId != null) {
        events = await _eventService.getEventsByArtist(widget.artistId!);
      } else if (widget.tags != null && widget.tags!.isNotEmpty) {
        events = await _eventService.getEventsByTags(widget.tags!);
      } else {
        events = await _eventService.getUpcomingPublicEvents();
      }

      if (mounted) {
        setState(() {
          _allEvents = events;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<ArtbeatEvent> filtered = List.from(_allEvents);

    // Apply tab filter
    switch (_currentTabIndex) {
      case 1: // Upcoming
        filtered = filtered
            .where((event) => event.dateTime.isAfter(DateTime.now()))
            .toList();
        break;
      case 2: // Today
        filtered = filtered
            .where((event) => EventUtils.isEventToday(event.dateTime))
            .toList();
        break;
      case 3: // This Week
        filtered = filtered
            .where((event) => EventUtils.isEventThisWeek(event.dateTime))
            .toList();
        break;
    }

    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((event) =>
              event.title.toLowerCase().contains(searchQuery) ||
              event.description.toLowerCase().contains(searchQuery) ||
              event.location.toLowerCase().contains(searchQuery) ||
              event.tags.any((tag) => tag.toLowerCase().contains(searchQuery)))
          .toList();
    }

    // Sort by date
    filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    setState(() {
      _filteredEvents = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 3, // Events tab
      child: Scaffold(
        appBar: UniversalHeader(
          title: widget.title ?? 'Events',
          showLogo: false,
          onSearchPressed: _showSearchDialog,
          actions: [
            if (widget.showCreateButton)
              IconButton(
                onPressed: _navigateToCreateEvent,
                icon: const Icon(Icons.add),
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
              if (_searchController.text.isNotEmpty) _buildSearchHeader(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
        floatingActionButton: widget.showCreateButton
            ? FloatingActionButton(
                onPressed: _navigateToCreateEvent,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Icon(Icons.search, color: ArtbeatColors.primaryPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Searching for "${_searchController.text}"',
              style: const TextStyle(
                color: ArtbeatColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              _searchController.clear();
              _applyFilters();
            },
            icon: const Icon(Icons.close, color: ArtbeatColors.textSecondary),
          ),
        ],
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

    if (_filteredEvents.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredEvents.length,
        itemBuilder: (context, index) {
          final event = _filteredEvents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: EventCard(
              event: event,
              onTap: () => _navigateToEventDetails(event),
              showTicketInfo: true,
              showArtistInfo: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ArtbeatColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtbeatColors.error.withAlpha(51)),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.error.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: ArtbeatColors.error.withAlpha(179),
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load events',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ArtbeatColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadEvents,
            style: ElevatedButton.styleFrom(
              backgroundColor: ArtbeatColors.primaryPurple,
              foregroundColor: ArtbeatColors.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;

    switch (_currentTabIndex) {
      case 1: // Upcoming
        message = 'No upcoming events';
        subtitle = 'Check back later for new events';
        icon = Icons.schedule;
        break;
      case 2: // Today
        message = 'No events today';
        subtitle = 'Check the upcoming events tab';
        icon = Icons.today;
        break;
      case 3: // This Week
        message = 'No events this week';
        subtitle = 'Check the upcoming events tab';
        icon = Icons.calendar_view_week;
        break;
      default:
        if (_searchController.text.isNotEmpty) {
          message = 'No events found';
          subtitle = 'Try different search terms';
          icon = Icons.search_off;
        } else {
          message = 'No events available';
          subtitle = 'Events will appear here when created';
          icon = Icons.event_busy;
        }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: ArtbeatColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtbeatColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: ArtbeatColors.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ArtbeatColors.textSecondary),
          ),
          if (widget.showCreateButton) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateEvent,
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryGreen,
                foregroundColor: ArtbeatColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Events'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by title, description, or location',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _applyFilters(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _navigateToEventDetails(ArtbeatEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(event: event),
      ),
    );
  }

  void _navigateToCreateEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEventScreen(),
      ),
    ).then((_) => _loadEvents()); // Refresh list after creating event
  }
}
