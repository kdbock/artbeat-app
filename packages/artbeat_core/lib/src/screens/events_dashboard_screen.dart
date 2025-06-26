import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_layout.dart';
import '../widgets/artbeat_drawer.dart';

/// Central events dashboard screen - entry point for events tab
/// This is a placeholder that redirects to the comprehensive events system
class EventsDashboardScreen extends StatelessWidget {
  const EventsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return MainLayout(
      currentIndex: 3, // Events tab
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Events'),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/events/all'),
              icon: const Icon(Icons.search),
              tooltip: 'Browse All Events',
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuSelection(context, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'all_events',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_outlined),
                      SizedBox(width: 8),
                      Text('All Events'),
                    ],
                  ),
                ),
                if (currentUser != null) ...[
                  const PopupMenuItem(
                    value: 'create_event',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text('Create Event'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'my_tickets',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.confirmation_number_outlined),
                        SizedBox(width: 8),
                        Text('My Tickets'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'my_events',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined),
                        SizedBox(width: 8),
                        Text('My Events'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        drawer: const ArtbeatDrawer(),
        body: _buildEventsDashboard(context, currentUser),
        floatingActionButton: currentUser != null
            ? FloatingActionButton(
                onPressed: () => Navigator.pushNamed(context, '/events/create'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Widget _buildEventsDashboard(BuildContext context, User? currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          _buildWelcomeHeader(context, currentUser),
          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(context, currentUser),
          const SizedBox(height: 24),

          // Events Overview
          _buildEventsOverview(context),
          const SizedBox(height: 24),

          // Getting Started (for new users)
          if (currentUser == null) _buildGettingStarted(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, User? currentUser) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentUser != null ? 'Welcome back!' : 'Discover Events',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentUser != null
                ? 'Manage your events, view tickets, and discover new experiences.'
                : 'Find amazing art events, exhibitions, and workshops in your area.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, User? currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              context,
              icon: Icons.event_outlined,
              title: 'All Events',
              subtitle: 'Browse all events',
              onTap: () => Navigator.pushNamed(context, '/events/all'),
            ),
            if (currentUser != null) ...[
              _buildActionCard(
                context,
                icon: Icons.confirmation_number_outlined,
                title: 'My Tickets',
                subtitle: 'View your tickets',
                onTap: () => Navigator.pushNamed(context, '/events/my-tickets'),
              ),
              _buildActionCard(
                context,
                icon: Icons.add_circle_outlined,
                title: 'Create Event',
                subtitle: 'Host an event',
                onTap: () => Navigator.pushNamed(context, '/events/create'),
              ),
              _buildActionCard(
                context,
                icon: Icons.calendar_today_outlined,
                title: 'My Events',
                subtitle: 'Manage events',
                onTap: () => Navigator.pushNamed(context, '/events/my-events'),
              ),
            ] else ...[
              _buildActionCard(
                context,
                icon: Icons.login,
                title: 'Sign In',
                subtitle: 'Access full features',
                onTap: () => Navigator.pushNamed(context, '/login'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Events Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/events/all'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(
                Icons.event_available,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Comprehensive Events System',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create events, sell tickets, manage attendees, and more with the new ARTbeat Events system.',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/events/all'),
                child: const Text('Explore Events'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGettingStarted(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Getting Started',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'Sign in to unlock all features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Purchase event tickets'),
                const Text('• Create and manage your own events'),
                const Text('• View your ticket history'),
                const Text('• Get event reminders'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text('Sign In Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'all_events':
        Navigator.pushNamed(context, '/events/all');
        break;
      case 'create_event':
        Navigator.pushNamed(context, '/events/create');
        break;
      case 'my_tickets':
        Navigator.pushNamed(context, '/events/my-tickets');
        break;
      case 'my_events':
        Navigator.pushNamed(context, '/events/my-events');
        break;
    }
  }
}
