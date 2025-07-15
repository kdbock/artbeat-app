import 'package:device_calendar/device_calendar.dart';
import 'package:logger/logger.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/artbeat_event.dart';

/// Service for integrating events with device calendar
class CalendarIntegrationService {
  final Logger _logger = Logger();
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  /// Add event to device calendar
  Future<bool> addEventToCalendar(ArtbeatEvent event) async {
    try {
      // Check permissions first
      final permissionsGranted = await _requestCalendarPermissions();
      if (!permissionsGranted) {
        _logger.w('Calendar permissions not granted');
        return false;
      }

      // Get default calendar
      final calendar = await _getDefaultCalendar();
      if (calendar == null) {
        _logger.w('No calendar available');
        return false;
      }

      // Create calendar event
      final calendarEvent = Event(
        calendar.id,
        title: event.title,
        description: _buildEventDescription(event),
        location: event.location,
        start: tz.TZDateTime.from(event.dateTime, tz.local),
        end: tz.TZDateTime.from(
          event.dateTime.add(const Duration(hours: 2)),
          tz.local,
        ),
      );

      final result = await _deviceCalendarPlugin.createOrUpdateEvent(
        calendarEvent,
      );

      if (result?.isSuccess == true) {
        _logger.i('Event added to calendar: ${event.title}');
        return true;
      } else {
        _logger.w('Failed to add event to calendar: ${result?.errors}');
        return false;
      }
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

      // Get default calendar first
      final calendar = await _getDefaultCalendar();
      if (calendar == null) {
        _logger.w('No calendar available for reminder');
        return false;
      }

      final reminderEvent = Event(
        calendar.id,
        title: 'Reminder: ${event.title}',
        description:
            'Your event "${event.title}" starts in ${_formatDuration(reminderBefore)} at ${event.location}',
        location: event.location,
        start: tz.TZDateTime.from(reminderTime, tz.local),
        end: tz.TZDateTime.from(
          reminderTime.add(const Duration(minutes: 15)),
          tz.local,
        ),
      );

      final result = await _deviceCalendarPlugin.createOrUpdateEvent(
        reminderEvent,
      );

      if (result?.isSuccess == true) {
        _logger.i('Event reminder added to calendar: ${event.title}');
        return true;
      } else {
        _logger.w(
          'Failed to add event reminder to calendar: ${result?.errors}',
        );
        return false;
      }
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
      return await _requestCalendarPermissions();
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

  /// Request calendar permissions from the user
  Future<bool> _requestCalendarPermissions() async {
    try {
      final permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && permissionsGranted.data == true) {
        return true;
      }

      final requestPermissionsResult = await _deviceCalendarPlugin
          .requestPermissions();
      return requestPermissionsResult.isSuccess &&
          requestPermissionsResult.data == true;
    } on Exception catch (e) {
      _logger.e('Error requesting calendar permissions: $e');
      return false;
    }
  }

  /// Get the default calendar for the device
  Future<Calendar?> _getDefaultCalendar() async {
    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        final calendars = calendarsResult.data!;

        // Try to find the default calendar
        final defaultCalendar = calendars.firstWhere(
          (calendar) => calendar.isDefault == true,
          orElse: () => calendars.first,
        );

        return defaultCalendar;
      }
    } on Exception catch (e) {
      _logger.e('Error getting default calendar: $e');
    }
    return null;
  }
}
