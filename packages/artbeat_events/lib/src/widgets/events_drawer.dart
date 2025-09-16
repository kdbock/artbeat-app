import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/artbeat_event.dart';
import '../services/event_service.dart';

/// Events navigation drawer with user profile and event-specific navigation options
class EventsDrawer extends StatefulWidget {
  const EventsDrawer({super.key});

  @override
  State<EventsDrawer> createState() => _EventsDrawerState();
}

class _EventsDrawerState extends State<EventsDrawer> {
  UserModel? _currentUser;
  bool _isLoading = true;
  List<ArtbeatEvent> _userEvents = [];
  List<ArtbeatEvent> _upcomingEvents = [];

  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadUserEvents();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _currentUser = UserModel.fromFirestore(userDoc);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } on Exception catch (e) {
      AppLogger.error('Error loading current user: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserEvents() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userEvents = await _eventService.getEventsByArtist(user.uid);
        final upcomingEvents = await _eventService.getUpcomingPublicEvents(
          limit: 5,
        );

        if (mounted) {
          setState(() {
            _userEvents = userEvents;
            _upcomingEvents = upcomingEvents;
          });
        }
      }
    } on Exception catch (e) {
      AppLogger.error('Error loading user events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE74C3C), // Red
                Color(0xFF3498DB), // Light Blue
                Colors.white,
              ],
              stops: [0.0, 0.3, 0.3],
            ),
          ),
          child: Column(
            children: [
              // User profile header
              _buildUserProfileHeader(),

              // Navigation items
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDrawerItem(
                        icon: Icons.event,
                        title: 'Events Dashboard',
                        onTap: () =>
                            _navigateToScreen(context, '/events/dashboard'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.add_circle,
                        title: 'Create Event',
                        onTap: () =>
                            _navigateToScreen(context, '/events/create'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.event_note,
                        title: 'My Events',
                        onTap: () =>
                            _navigateToScreen(context, '/events/my-events'),
                        badge: _userEvents.isNotEmpty
                            ? _userEvents.length.toString()
                            : null,
                      ),
                      _buildDrawerItem(
                        icon: Icons.confirmation_number,
                        title: 'My Tickets',
                        onTap: () =>
                            _navigateToScreen(context, '/events/my-tickets'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.calendar_today,
                        title: 'Calendar',
                        onTap: () => _navigateToScreen(
                          context,
                          '/events/dashboard',
                        ), // Redirect to dashboard for now
                      ),
                      _buildDrawerItem(
                        icon: Icons.location_on,
                        title: 'Nearby Events',
                        onTap: () => _navigateToScreen(
                          context,
                          '/events/discover',
                        ), // Use discover route
                      ),
                      _buildDrawerItem(
                        icon: Icons.search,
                        title: 'Search Events',
                        onTap: () => _navigateToScreen(
                          context,
                          '/search',
                        ), // Use main search
                      ),
                      const Divider(),
                      _buildDrawerItem(
                        icon: Icons.notifications,
                        title: 'Event Notifications',
                        onTap: () => _navigateToScreen(
                          context,
                          '/notifications',
                        ), // Use main notifications
                      ),
                      _buildDrawerItem(
                        icon: Icons.settings,
                        title: 'Event Settings',
                        onTap: () => _navigateToScreen(
                          context,
                          '/settings',
                        ), // Use main settings
                      ),
                      _buildDrawerItem(
                        icon: Icons.help,
                        title: 'Event Help',
                        onTap: () => _navigateToScreen(
                          context,
                          '/support',
                        ), // Use main support
                      ),
                    ],
                  ),
                ),
              ),

              // Footer with version info
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: const Text(
                  'ARTbeat Events v1.0.1',
                  style: TextStyle(
                    color: ArtbeatColors.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      child: Column(
        children: [
          // User avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFE74C3C),
                    ),
                  )
                : _currentUser?.profileImageUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _currentUser!.profileImageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFFE74C3C),
                      ),
                    ),
                  )
                : const Icon(Icons.person, size: 40, color: Color(0xFFE74C3C)),
          ),

          const SizedBox(height: 12),

          // User name
          Text(
            _isLoading
                ? 'Loading...'
                : _currentUser?.fullName ?? 'Event Attendee',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // User role/status
          Text(
            _isLoading ? '' : _getUserRoleText(),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Quick stats
          if (!_isLoading && _currentUser != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip('${_userEvents.length}', 'My Events'),
                const SizedBox(width: 8),
                _buildStatChip('${_upcomingEvents.length}', 'Upcoming'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _getUserRoleText() {
    if (_currentUser == null) return 'Attendee';

    final userType = _currentUser!.userType;
    if (userType == null) return 'Event Attendee';

    switch (userType) {
      case 'artist':
        return 'Event Artist';
      case 'business':
        return 'Event Organizer';
      case 'moderator':
        return 'Event Moderator';
      case 'admin':
        return 'Event Admin';
      default:
        return 'Event Attendee';
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badge,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFE74C3C)),
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ArtbeatColors.textPrimary,
              fontSize: 16,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _navigateToScreen(BuildContext context, String routeName) {
    Navigator.pop(context); // Close drawer
    Navigator.pushNamed(context, routeName);
  }
}
