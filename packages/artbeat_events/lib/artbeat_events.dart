/// ARTbeat Events Package
///
/// A comprehensive event management system for the ARTbeat app.
/// Features include:
/// - Event creation and management
/// - Multiple ticket types (free, paid, VIP)
/// - Refund policies and management
/// - Notifications and reminders
/// - Calendar integration
/// - Community feed integration
library;

// Models
export 'src/models/artbeat_event.dart';
export 'src/models/ticket_type.dart';
export 'src/models/refund_policy.dart';
export 'src/models/ticket_purchase.dart';

// Screens
export 'src/screens/event_details_screen.dart';
export 'src/screens/events_list_screen.dart';
export 'src/screens/create_event_screen.dart';
export 'src/screens/events_dashboard_screen.dart';
export 'src/screens/my_tickets_screen.dart';

// Forms
export 'src/forms/event_form_builder.dart';

// Services
export 'src/services/event_service.dart';
export 'src/services/calendar_integration_service.dart';
export 'src/services/event_notification_service.dart';

// Utils
export 'src/utils/event_utils.dart';

// Widgets
export 'src/widgets/event_card.dart';
export 'src/widgets/ticket_purchase_sheet.dart';
