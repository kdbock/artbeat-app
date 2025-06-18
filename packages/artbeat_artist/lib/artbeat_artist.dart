/// ARTbeat Artist package with artist and gallery functionality
library;

// Models
export 'src/models/artist_profile_model.dart'
    hide ArtistProfileModel; // Hide to avoid conflict with core
export 'src/models/commission_model.dart';
export 'src/models/gallery_invitation_model.dart';
export 'src/models/subscription_model.dart';

// Screens
export 'src/screens/analytics_dashboard_screen.dart';
export 'src/screens/artist_browse_screen.dart';
export 'src/screens/artist_dashboard_screen.dart';
export 'src/screens/artist_onboarding_screen.dart';
export 'src/screens/artist_profile_edit_screen.dart';
export 'src/screens/artist_public_profile_screen.dart';
export 'src/screens/artwork_browse_screen.dart';
export 'src/screens/event_creation_screen.dart';
export 'src/screens/events_screen.dart';
export 'src/screens/gallery_analytics_dashboard_screen.dart';
export 'src/screens/gallery_artists_management_screen.dart';
export 'src/screens/payment_methods_screen.dart';
export 'src/screens/payment_screen.dart';
export 'src/screens/refund_request_screen.dart';
export 'src/screens/subscription_analytics_screen.dart';
export 'src/screens/subscription_comparison_screen.dart';
export 'src/screens/subscription_screen.dart';

// Services
export 'src/services/analytics_service.dart';
export 'src/services/artist_profile_service.dart';
export 'src/services/subscription_service.dart';
export 'src/services/gallery_invitation_service.dart';
export 'src/services/event_service.dart';
