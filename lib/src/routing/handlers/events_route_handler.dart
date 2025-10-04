import 'package:artbeat_events/artbeat_events.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_routes.dart';

class EventsRouteHandler {
  static Widget handleEventsRoute(String routeName, Object? arguments) {
    switch (routeName) {
      case AppRoutes.allEvents:
        return const EventsListScreen();
      case AppRoutes.artistEvents:
        return const EventsDashboardScreen();
      case AppRoutes.myTickets:
        // Get current user ID from Firebase Auth
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return MyTicketsScreen(userId: userId);
      case AppRoutes.createEvent:
        return const CreateEventScreen();
      case AppRoutes.myEvents:
        return const UserEventsDashboardScreen();
      case AppRoutes.eventsSearch:
        return const EventSearchScreen();
      case AppRoutes.eventsNearby:
        // Navigate to EventsListScreen showing all events (location filtering can be added later)
        return const EventsListScreen();
      case '/events/trending':
        // Navigate to EventsListScreen showing all events
        return const EventsListScreen();
      case '/events/weekend':
        // Navigate to EventsListScreen showing all events
        return const EventsListScreen();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }
}
