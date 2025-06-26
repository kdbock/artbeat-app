import 'package:flutter/material.dart';
import 'package:artbeat_events/artbeat_events.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Screen showing user's created events - accessible from drawer
class MyEventsDrawerScreen extends StatelessWidget {
  const MyEventsDrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/events/create'),
            icon: const Icon(Icons.add),
            tooltip: 'Create Event',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuSelection(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'analytics',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics_outlined),
                    SizedBox(width: 8),
                    Text('Event Analytics'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.archive_outlined),
                    SizedBox(width: 8),
                    Text('Archived Events'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: const ArtbeatDrawer(),
      body: currentUser != null
          ? EventsListScreen(
              title: 'My Events',
              artistId: currentUser.uid,
              showCreateButton: true,
            )
          : _buildSignInRequired(context),
      floatingActionButton: currentUser != null
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/events/create'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSignInRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Sign In Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please sign in to view and manage your events',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/events/all'),
              icon: const Icon(Icons.event_outlined),
              label: const Text('Browse Events'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'analytics':
        // TODO: Navigate to event analytics screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event analytics coming soon!'),
          ),
        );
        break;
      case 'archive':
        // TODO: Navigate to archived events screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archived events coming soon!'),
          ),
        );
        break;
    }
  }
}