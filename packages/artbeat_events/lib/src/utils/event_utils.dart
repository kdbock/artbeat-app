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
    
    return eventDateTime.isAfter(startOfWeek) && eventDateTime.isBefore(endOfWeek);
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
    
    buffer.writeln('🎨 ${event.title}');
    buffer.writeln('📅 ${formatEventDateTime(event.dateTime)}');
    buffer.writeln('📍 ${event.location}');
    
    final priceRange = getTicketPriceRange(event.ticketTypes);
    buffer.writeln('🎫 $priceRange');
    
    if (event.tags.isNotEmpty) {
      buffer.writeln('🏷️ ${event.tags.take(3).join(' • ')}');
    }
    
    buffer.writeln('\n${event.description}');
    buffer.writeln('\nGet your tickets on ARTbeat!');
    
    return buffer.toString();
  }

  /// Get event category from tags
  static String getEventCategory(List<String> tags) {
    if (tags.isEmpty) return 'General';
    
    // Priority categories
    const priorityCategories = [
      'Art Exhibition',
      'Gallery Opening',
      'Workshop',
      'Artist Talk',
      'Live Performance',
    ];
    
    for (final category in priorityCategories) {
      if (tags.contains(category)) {
        return category;
      }
    }
    
    return tags.first;
  }

  /// Calculate event popularity score
  static double calculatePopularityScore(ArtbeatEvent event) {
    double score = 0.0;
    
    // Base score from attendees
    final attendeeRatio = event.attendeeIds.length / event.maxAttendees;
    score += attendeeRatio * 50;
    
    // Bonus for ticket sales
    final salesRatio = event.totalTicketsSold / event.totalAvailableTickets;
    score += salesRatio * 30;
    
    // Bonus for being public
    if (event.isPublic) {
      score += 10;
    }
    
    // Bonus for having tags
    score += event.tags.length * 2;
    
    // Time penalty for older events
    final daysSinceCreated = DateTime.now().difference(event.createdAt).inDays;
    score *= (1 - (daysSinceCreated * 0.01)).clamp(0.5, 1.0);
    
    return score.clamp(0.0, 100.0);
  }

  /// Sort events by relevance
  static List<ArtbeatEvent> sortEventsByRelevance(
    List<ArtbeatEvent> events, {
    List<String>? userInterests,
    DateTime? referenceDate,
  }) {
    final reference = referenceDate ?? DateTime.now();
    
    events.sort((a, b) {
      double scoreA = 0.0;
      double scoreB = 0.0;
      
      // Time relevance (upcoming events are more relevant)
      final daysUntilA = a.dateTime.difference(reference).inDays;
      final daysUntilB = b.dateTime.difference(reference).inDays;
      
      if (daysUntilA >= 0 && daysUntilA <= 7) scoreA += 10;
      if (daysUntilB >= 0 && daysUntilB <= 7) scoreB += 10;
      
      // Interest matching
      if (userInterests != null) {
        final matchingTagsA = a.tags.where((tag) => userInterests.contains(tag)).length;
        final matchingTagsB = b.tags.where((tag) => userInterests.contains(tag)).length;
        
        scoreA += matchingTagsA * 5;
        scoreB += matchingTagsB * 5;
      }
      
      // Popularity
      scoreA += calculatePopularityScore(a) * 0.1;
      scoreB += calculatePopularityScore(b) * 0.1;
      
      return scoreB.compareTo(scoreA);
    });
    
    return events;
  }

  /// Generate QR code data for event
  static String generateEventQrCode(ArtbeatEvent event) {
    return 'artbeat://event/${event.id}';
  }

  /// Parse QR code data
  static String? parseEventIdFromQrCode(String qrData) {
    final regex = RegExp(r'artbeat://event/(.+)');
    final match = regex.firstMatch(qrData);
    return match?.group(1);
  }
}