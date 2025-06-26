import 'package:flutter/material.dart';
import 'package:artbeat_events/artbeat_events.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Screen for creating events - accessible from drawer
class CreateEventDrawerScreen extends StatelessWidget {
  const CreateEventDrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Event'),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        drawer: const ArtbeatDrawer(),
        body: _buildSignInRequired(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/events/my-events'),
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'My Events',
          ),
        ],
      ),
      drawer: const ArtbeatDrawer(),
      body: const CreateEventScreen(),
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
              Icons.event_note_outlined,
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
              'Please sign in to create events',
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
}