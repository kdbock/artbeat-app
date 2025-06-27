import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:logger/logger.dart';
import '../models/artbeat_event.dart';

/// Service for integrating events with device calendar
class CalendarIntegrationService {
  final Logger _logger = Logger();

  /// Add event to device calendar
  Future<bool> addEventToCalendar(ArtbeatEvent event) async {
    try {
      final calendarEvent = Event(
        title: event.title,
        description: _buildEventDescription(event),
        location: event.location,
        startDate: event.dateTime,
        endDate: event.dateTime.add(
          const Duration(hours: 2),
        ), // Default 2-hour duration
      );

      final success = await Add2Calendar.addEvent2Cal(calendarEvent);

      if (success) {
        _logger.i('Event added to calendar: ${event.title}');
      } else {
        _logger.w('Failed to add event to calendar: ${event.title}');
      }

      return success;
    } on Exception catch (e) {
      _logger.e('Error adding event to calendar: $e');
      return false;
    }
  }

  /// Build detailed event description for calendar
  String _buildEventDescription(ArtbeatEvent event) {
    final buffer = StringBuffer();

    buffer.writeln(event.description);
    buffer.writeln();

    // Add ticket information
    if (event.ticketTypes.isNotEmpty) {
      buffer.writeln('🎫 Tickets:');
      for (final ticket in event.ticketTypes) {
        buffer.writeln('• ${ticket.name}: ${ticket.formattedPrice}');
      }
      buffer.writeln();
    }

    // Add contact information
    buffer.writeln('📧 Contact: ${event.contactEmail}');
    if (event.contactPhone != null && event.contactPhone!.isNotEmpty) {
      buffer.writeln('📞 Phone: ${event.contactPhone}');
    }
    buffer.writeln();

    // Add tags
    if (event.tags.isNotEmpty) {
      buffer.writeln('🏷️ Tags: ${event.tags.join(', ')}');
      buffer.writeln();
    }

    // Add refund policy
    buffer.writeln('🔄 Refund Policy: ${event.refundPolicy.terms}');
    buffer.writeln();

    buffer.writeln('Created with ARTbeat');

    return buffer.toString();
  }

  /// Create calendar reminder for event
  Future<bool> addEventReminder(
    ArtbeatEvent event, {
    Duration reminderBefore = const Duration(hours: 1),
  }) async {
    try {
      final reminderTime = event.dateTime.subtract(reminderBefore);

      final reminderEvent = Event(
        title: 'Reminder: ${event.title}',
        description:
            'Your event "${event.title}" starts in ${_formatDuration(reminderBefore)} at ${event.location}',
        location: event.location,
        startDate: reminderTime,
        endDate: reminderTime.add(
          const Duration(minutes: 15),
        ), // 15-minute reminder
      );

      final success = await Add2Calendar.addEvent2Cal(reminderEvent);

      if (success) {
        _logger.i('Event reminder added to calendar: ${event.title}');
      } else {
        _logger.w('Failed to add event reminder to calendar: ${event.title}');
      }

      return success;
    } on Exception catch (e) {
      _logger.e('Error adding event reminder to calendar: $e');
      return false;
    }
  }

  /// Format duration for human-readable display
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'now';
    }
  }

  /// Check if calendar permissions are available
  Future<bool> hasCalendarPermissions() async {
    try {
      // Create a test event to check permissions
      final testEvent = Event(
        title: 'Test Event',
        description: 'This is a test event',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(minutes: 1)),
      );

      // This will return false if permissions are not granted
      return await Add2Calendar.addEvent2Cal(testEvent);
    } on Exception catch (e) {
      _logger.e('Error checking calendar permissions: $e');
      return false;
    }
  }

  /// Create iCalendar (.ics) format string for sharing
  String createICalendarString(ArtbeatEvent event) {
    final startDate = _formatDateTimeForICal(event.dateTime);
    final endDate = _formatDateTimeForICal(
      event.dateTime.add(const Duration(hours: 2)),
    );
    final createdDate = _formatDateTimeForICal(DateTime.now());

    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//ARTbeat//Event Manager//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('UID:${event.id}@artbeat.app');
    buffer.writeln('DTSTART:$startDate');
    buffer.writeln('DTEND:$endDate');
    buffer.writeln('DTSTAMP:$createdDate');
    buffer.writeln('CREATED:$createdDate');
    buffer.writeln('SUMMARY:${_escapeICalText(event.title)}');
    buffer.writeln(
      'DESCRIPTION:${_escapeICalText(_buildEventDescription(event))}',
    );
    buffer.writeln('LOCATION:${_escapeICalText(event.location)}');
    buffer.writeln('STATUS:CONFIRMED');
    buffer.writeln('TRANSP:OPAQUE');

    // Add categories/tags
    if (event.tags.isNotEmpty) {
      buffer.writeln('CATEGORIES:${event.tags.map(_escapeICalText).join(',')}');
    }

    // Add organizer (contact email)
    buffer.writeln('ORGANIZER;CN=Event Organizer:mailto:${event.contactEmail}');

    // Add URL if available
    buffer.writeln('URL:https://artbeat.app/events/${event.id}');

    buffer.writeln('END:VEVENT');
    buffer.writeln('END:VCALENDAR');

    return buffer.toString();
  }

  /// Format DateTime for iCalendar format (YYYYMMDDTHHMMSSZ)
  String _formatDateTimeForICal(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}'
        'T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}'
        'Z';
  }

  /// Escape special characters for iCalendar format
  String _escapeICalText(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r');
  }
}
