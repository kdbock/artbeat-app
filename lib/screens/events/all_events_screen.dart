import 'package:flutter/material.dart';
import 'package:artbeat_events/artbeat_events.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Screen showing all public events - accessible from drawer
class AllEventsScreen extends StatelessWidget {
  const AllEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Events'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () => _navigateToSearch(context),
            icon: const Icon(Icons.search),
            tooltip: 'Search Events',
          ),
        ],
      ),
      drawer: const ArtbeatDrawer(),
      body: const EventsListScreen(
        title: 'All Events',
        showCreateButton: false,
      ),
    );
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EventsListScreen(
          title: 'Search Events',
          showCreateButton: false,
        ),
      ),
    );
  }
}
