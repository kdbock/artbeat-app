// import 'package:device_calendar/device_calendar.dart'; // Plugin removed
import 'package:logger/logger.dart';
// import 'package:timezone/timezone.dart' as tz; // Not needed without calendar plugin
import '../models/artbeat_event.dart';

/// Service for integrating events with device calendar
/// NOTE: Calendar integration is currently disabled due to plugin removal
class CalendarIntegrationService {
  final Logger _logger = Logger();
  // final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin(); // Disabled

  /// Add event to device calendar
  /// NOTE: This functionality is currently disabled
  Future<bool> addEventToCalendar(ArtbeatEvent event) async {
    _logger.w(
      'Calendar integration is currently disabled - device_calendar plugin removed',
    );
    return false; // Return false to indicate failure
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
  /// NOTE: This functionality is currently disabled
  Future<bool> addEventReminder(
    ArtbeatEvent event, {
    Duration reminderBefore = const Duration(hours: 1),
  }) async {
    _logger.w(
      'Calendar reminder functionality is currently disabled - device_calendar plugin removed',
    );
    return false; // Return false to indicate failure
  }

  /// Check if calendar permissions are available
  /// NOTE: This functionality is currently disabled
  Future<bool> hasCalendarPermissions() async {
    _logger.w(
      'Calendar permissions check is currently disabled - device_calendar plugin removed',
    );
    return false; // Return false since plugin is not available
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
