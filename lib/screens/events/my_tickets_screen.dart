import 'package:flutter/material.dart';
import 'package:artbeat_events/artbeat_events.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Screen showing user's purchased tickets - accessible from drawer
class MyTicketsDrawerScreen extends StatelessWidget {
  const MyTicketsDrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () => _navigateToAllEvents(context),
            icon: const Icon(Icons.event_outlined),
            tooltip: 'Browse Events',
          ),
        ],
      ),
      drawer: const ArtbeatDrawer(),
      body: currentUser != null
          ? MyTicketsScreen(userId: currentUser.uid)
          : _buildSignInRequired(context),
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
              Icons.confirmation_number_outlined,
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
              'Please sign in to view your tickets',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _navigateToAllEvents(context),
              icon: const Icon(Icons.event_outlined),
              label: const Text('Browse Events'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAllEvents(BuildContext context) {
    Navigator.pushNamed(context, '/events/all');
  }
}
