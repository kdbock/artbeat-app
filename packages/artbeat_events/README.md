# ARTbeat Events Package

A comprehensive event management system for the ARTbeat app that handles creation, display, and ticketing of artist-hosted events within the ARTbeat ecosystem.

## Features

### ✨ Core Features
- **Event Creation & Management**: Intuitive form for artists to create events
- **Multiple Image Support**: Event banner, artist headshot, and additional event images
- **Comprehensive Ticketing**: Free, paid, and VIP ticket types with benefits
- **Refund Management**: Configurable refund policies with automatic enforcement
- **Community Integration**: Events display in Community Feed and Dashboard
- **Notifications & Reminders**: Local notifications and calendar integration
- **QR Code Tickets**: Digital tickets with QR codes for easy validation

### 🎫 Ticket Types
- **Free Tickets**: No payment required, instant confirmation
- **Paid Tickets**: Stripe integration for secure payments
- **VIP Tickets**: Premium tickets with customizable benefits and inclusions

### 📱 User Experience
- **Community Feed Integration**: Events appear in the main community feed
- **Dashboard Integration**: Replace artwork tab with Events tab
- **Search & Filtering**: Find events by title, description, location, or tags
- **Calendar Integration**: Add events to device calendar (Google/Apple)
- **Real-time Updates**: Live ticket availability and event updates

### 🔔 Notifications
- **Event Reminders**: Customizable notifications before events
- **Purchase Confirmations**: Instant confirmation for ticket purchases
- **Refund Notifications**: Automatic notifications for refund processing
- **Event Updates**: Notify attendees of important event changes

## Package Structure

```
lib/
├── src/
│   ├── models/           # Data models
│   │   ├── artbeat_event.dart
│   │   ├── ticket_type.dart
│   │   ├── refund_policy.dart
│   │   └── ticket_purchase.dart
│   ├── forms/            # Form builders
│   │   └── event_form_builder.dart
│   ├── widgets/          # Reusable widgets
│   │   ├── event_card.dart
│   │   ├── ticket_type_builder.dart
│   │   ├── community_feed_events_widget.dart
│   │   ├── ticket_purchase_sheet.dart
│   │   └── qr_code_ticket_widget.dart
│   ├── screens/          # Full screen widgets
│   │   ├── event_details_screen.dart
│   │   ├── events_list_screen.dart
│   │   ├── create_event_screen.dart
│   │   └── my_tickets_screen.dart
│   ├── services/         # Business logic services
│   │   ├── event_service.dart
│   │   ├── event_notification_service.dart
│   │   └── calendar_integration_service.dart
│   └── utils/            # Utility functions
│       └── event_utils.dart
└── artbeat_events.dart   # Main export file
```

## Quick Start

### 1. Add Dependency

Add to your `pubspec.yaml`:

```yaml
dependencies:
  artbeat_events:
    path: ../packages/artbeat_events
```

### 2. Import the Package

```dart
import 'package:artbeat_events/artbeat_events.dart';
```

### 3. Initialize Services

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if Firebase is already initialized to avoid duplicate initialization
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  
  // Initialize notification service
  await EventNotificationService().initialize();
  await EventNotificationService().requestPermissions();
  
  runApp(MyApp());
}
```

### 4. Display Events in Community Feed

```dart
// In your community feed screen
CommunityFeedEventsWidget(
  limit: 5, // Show 5 events
  showHeader: true,
  onViewAllPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EventsListScreen(
          title: 'All Events',
        ),
      ),
    );
  },
)
```

### 5. Create Events

```dart
// Navigate to event creation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CreateEventScreen(),
  ),
);
```

### 6. View User's Tickets

```dart
// Show user's purchased tickets
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MyTicketsScreen(
      userId: currentUser.uid,
    ),
  ),
);
```

## Usage Examples

### Creating an Event

```dart
final event = ArtbeatEvent.create(
  title: 'Contemporary Art Exhibition',
  description: 'Featuring works by local contemporary artists...',
  artistId: 'artist_123',
  imageUrls: ['image1.jpg', 'image2.jpg'],
  artistHeadshotUrl: 'headshot.jpg',
  eventBannerUrl: 'banner.jpg',
  dateTime: DateTime.now().add(Duration(days: 30)),
  location: 'Downtown Art Gallery, 123 Main St',
  ticketTypes: [
    TicketType.free(
      id: 'general',
      name: 'General Admission',
      quantity: 100,
    ),
    TicketType.vip(
      id: 'vip',
      name: 'VIP Experience',
      price: 50.0,
      quantity: 20,
      benefits: [
        'Early entry',
        'Meet & greet with artist',
        'Complimentary drinks',
        'Exclusive merchandise',
      ],
    ),
  ],
  contactEmail: 'artist@example.com',
);

// Save to Firestore
final eventId = await EventService().createEvent(event);
```

### Purchasing Tickets

```dart
// Purchase tickets through the service
final purchaseId = await EventService().purchaseTickets(
  eventId: 'event_123',
  ticketTypeId: 'vip',
  quantity: 2,
  userEmail: 'user@example.com',
  userName: 'John Doe',
  paymentIntentId: 'pi_stripe_payment_intent', // From Stripe
);
```

### Displaying Events

```dart
// Get upcoming events
final events = await EventService().getUpcomingPublicEvents(limit: 10);

// Display in a list
ListView.builder(
  itemCount: events.length,
  itemBuilder: (context, index) {
    return EventCard(
      event: events[index],
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventDetailsScreen(
            event: events[index],
          ),
        ),
      ),
      showTicketInfo: true,
    );
  },
);
```

## Services

### EventService

Main service for CRUD operations on events and ticket purchases.

```dart
final eventService = EventService();

// Create event
final eventId = await eventService.createEvent(event);

// Get events
final events = await eventService.getUpcomingPublicEvents();
final artistEvents = await eventService.getEventsByArtist(artistId);
final searchResults = await eventService.searchEvents('art exhibition');

// Purchase tickets
final purchaseId = await eventService.purchaseTickets(/* ... */);

// Get user tickets
final tickets = await eventService.getUserTicketPurchases(userId);
```

### EventNotificationService

Handles notifications and reminders for events.

```dart
final notificationService = EventNotificationService();

// Initialize (call once at app startup)
await notificationService.initialize();
await notificationService.requestPermissions();

// Schedule event reminders
await notificationService.scheduleEventReminders(event);

// Send purchase confirmation
await notificationService.sendTicketPurchaseConfirmation(
  eventTitle: event.title,
  quantity: 2,
  ticketType: 'VIP',
);
```

### CalendarIntegrationService

Integrates events with device calendar.

```dart
final calendarService = CalendarIntegrationService();

// Add event to calendar
final success = await calendarService.addEventToCalendar(event);

// Add reminder
await calendarService.addEventReminder(
  event,
  reminderBefore: Duration(hours: 1),
);

// Generate iCalendar file
final icsString = calendarService.createICalendarString(event);
```

## Models

### ArtbeatEvent

Main event model with comprehensive fields for event management.

### TicketType

Represents different types of tickets (free, paid, VIP) with pricing and benefits.

### RefundPolicy

Configurable refund policies with different deadline and percentage options.

### TicketPurchase

Tracks individual ticket purchases with payment information and status.

## Utilities

### EventUtils

Helper functions for formatting dates, calculating popularity, validation, and more.

```dart
// Format event date
final formattedDate = EventUtils.formatEventDateTime(event.dateTime);

// Get time until event
final timeUntil = EventUtils.getTimeUntilEvent(event.dateTime);

// Validate event data
final errors = EventUtils.validateEvent(event);

// Generate share text
final shareText = EventUtils.generateShareText(event);
```

## Integration with ARTbeat

### Community Feed Integration

Replace the existing community feed content with events:

```dart
// In community_feed.dart
CommunityFeedEventsWidget(
  limit: 10,
  showHeader: true,
  onViewAllPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const EventsListScreen(),
    ),
  ),
)
```

### Dashboard Integration

Replace the artwork tab with events:

```dart
// In dashboard_screen.dart
TabBarView(
  children: [
    // Other tabs...
    EventsListScreen(
      title: 'My Events',
      artistId: currentUser.uid,
      showCreateButton: true,
    ),
  ],
)
```

## Dependencies

- `cloud_firestore`: Firestore database integration
- `firebase_auth`: User authentication
- `firebase_storage`: Image storage
- `flutter_stripe`: Payment processing
- `flutter_local_notifications`: Local notifications
- `awesome_notifications`: Enhanced notifications
- `add_2_calendar`: Calendar integration
- `image_picker`: Image selection
- `qr_flutter`: QR code generation
- `intl`: Date formatting
- `uuid`: Unique ID generation

## Contributing

1. Follow the existing code style and patterns
2. Add tests for new functionality
3. Update documentation when adding features
4. Ensure Firebase security rules are updated for new collections

## License

This package is part of the ARTbeat application and follows the same licensing terms.