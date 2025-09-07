import 'package:intl/intl.dart';
import '../models/artbeat_event.dart';
import '../models/ticket_type.dart';

/// Utility functions for event management
class EventUtils {
  /// Format event date for display
  static String formatEventDate(DateTime dateTime) {
    return DateFormat('EEEE, MMMM d, y').format(dateTime);
  }

  /// Format event time for display
  static String formatEventTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Format event date and time for display
  static String formatEventDateTime(DateTime dateTime) {
    return DateFormat('EEEE, MMMM d, y \'at\' h:mm a').format(dateTime);
  }

  /// Format short event date (e.g., "Dec 25")
  static String formatShortEventDate(DateTime dateTime) {
    return DateFormat('MMM d').format(dateTime);
  }

  /// Get time until event starts
  static String getTimeUntilEvent(DateTime eventDateTime) {
    final now = DateTime.now();
    final difference = eventDateTime.difference(now);

    if (difference.isNegative) {
      return 'Event has ended';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} away';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} away';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} away';
    } else {
      return 'Starting now';
    }
  }

  /// Check if event is happening today
  static bool isEventToday(DateTime eventDateTime) {
    final now = DateTime.now();
    return eventDateTime.year == now.year &&
        eventDateTime.month == now.month &&
        eventDateTime.day == now.day;
  }

  /// Check if event is happening this week
  static bool isEventThisWeek(DateTime eventDateTime) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return eventDateTime.isAfter(startOfWeek) &&
        eventDateTime.isBefore(endOfWeek);
  }

  /// Get event status string
  static String getEventStatus(ArtbeatEvent event) {
    final now = DateTime.now();

    if (event.dateTime.isBefore(now)) {
      return 'Ended';
    }

    if (event.isSoldOut) {
      return 'Sold Out';
    }

    if (event.totalTicketsSold > event.totalAvailableTickets * 0.8) {
      return 'Almost Full';
    }

    return 'Available';
  }

  /// Get ticket price range display string
  static String getTicketPriceRange(List<TicketType> ticketTypes) {
    if (ticketTypes.isEmpty) return 'No tickets';

    final availableTickets = ticketTypes.where((t) => t.isAvailable).toList();
    if (availableTickets.isEmpty) return 'Sold Out';

    final prices = availableTickets.map((t) => t.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    if (minPrice == 0 && maxPrice == 0) {
      return 'Free';
    } else if (minPrice == 0) {
      return 'Free - \$${maxPrice.toStringAsFixed(2)}';
    } else if (minPrice == maxPrice) {
      return '\$${minPrice.toStringAsFixed(2)}';
    } else {
      return '\$${minPrice.toStringAsFixed(2)} - \$${maxPrice.toStringAsFixed(2)}';
    }
  }

  /// Validate event data
  static List<String> validateEvent(ArtbeatEvent event) {
    final errors = <String>[];

    if (event.title.trim().isEmpty) {
      errors.add('Event title is required');
    }

    if (event.description.trim().isEmpty) {
      errors.add('Event description is required');
    }

    if (event.location.trim().isEmpty) {
      errors.add('Event location is required');
    }

    if (event.contactEmail.trim().isEmpty) {
      errors.add('Contact email is required');
    } else if (!_isValidEmail(event.contactEmail)) {
      errors.add('Invalid contact email format');
    }

    if (event.dateTime.isBefore(DateTime.now())) {
      errors.add('Event date must be in the future');
    }

    if (event.ticketTypes.isEmpty) {
      errors.add('At least one ticket type is required');
    }

    for (final ticket in event.ticketTypes) {
      if (ticket.name.trim().isEmpty) {
        errors.add('Ticket type name is required');
      }
      if (ticket.quantity <= 0) {
        errors.add('Ticket quantity must be greater than 0');
      }
      if (ticket.price < 0) {
        errors.add('Ticket price cannot be negative');
      }
    }

    if (event.maxAttendees <= 0) {
      errors.add('Maximum attendees must be greater than 0');
    }

    final totalTickets = event.ticketTypes.fold<int>(
      0,
      (sum, ticket) => sum + ticket.quantity,
    );
    if (totalTickets > event.maxAttendees) {
      errors.add('Total tickets cannot exceed maximum attendees');
    }

    return errors;
  }

  /// Check if email is valid
  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Generate event share text
  static String generateShareText(ArtbeatEvent event) {
    final buffer = StringBuffer();

    // Event title and basic info
    buffer.writeln('🎨 ${event.title}');
    buffer.writeln('📅 ${formatEventDateTime(event.dateTime)}');
    buffer.writeln('📍 ${event.location}');

    // Ticket information
    final priceRange = getTicketPriceRange(event.ticketTypes);
    buffer.writeln('🎫 $priceRange');

    // Show remaining tickets if limited
    if (event.maxAttendees > 0) {
      final remaining = event.totalAvailableTickets - event.totalTicketsSold;
      if (remaining < event.totalAvailableTickets * 0.2) {
        // Less than 20% left
        buffer.writeln('⚠️ Only $remaining tickets remaining!');
      }
    }

    // Categories and tags
    if (event.tags.isNotEmpty) {
      buffer.writeln('🏷️ ${event.tags.take(3).join(' • ')}');
    }

    // Event description (truncated)
    final description = event.description.length > 200
        ? '${event.description.substring(0, 197)}...'
        : event.description;
    buffer.writeln('\n$description');

    // Call to action
    buffer.writeln('\nGet your tickets now at:');
    buffer.writeln('artbeat://events/${event.id}');

    return buffer.toString();
  }

  /// Get calendar event details
  static Map<String, dynamic> getCalendarEventDetails(ArtbeatEvent event) {
    return {
      'title': event.title,
      'description':
          '${event.description}\n\nLocation: ${event.location}\n'
          'Tickets: ${getTicketPriceRange(event.ticketTypes)}',
      'start': event.dateTime,
      'end': event.dateTime.add(
        const Duration(hours: 2),
      ), // Default 2 hour duration
      'location': event.location,
      'url': 'artbeat://events/${event.id}',
      'reminders': [const Duration(days: 1), const Duration(hours: 1)],
    };
  }

  /// Generate event QR code
  static String generateEventQrCode(ArtbeatEvent event) {
    return 'artbeat://event/${event.id}';
  }

  /// Parse QR code data
  static String? parseEventIdFromQrCode(String qrData) {
    final regex = RegExp('artbeat://event/(.+)');
    final match = regex.firstMatch(qrData);
    return match?.group(1);
  }
}
