// artbeat_core entry point

/// ARTbeat Core package with shared functionality
library artbeat_core;

// Export Firebase configuration
export 'src/firebase/secure_firebase_config.dart';

// Export Theme
export 'src/theme/artbeat_colors.dart' show ArtbeatColors;
export 'src/theme/artbeat_components.dart' show ArtbeatComponents;
export 'src/theme/artbeat_theme.dart' show ArtbeatTheme;
export 'src/theme/artbeat_typography.dart' show ArtbeatTypography;

// Export Core Services
export 'src/services/config_service.dart' show ConfigService;
export 'src/services/user_service.dart' show UserService;
export 'src/services/connectivity_service.dart' show ConnectivityService;
export 'src/services/subscription_service.dart' show SubscriptionService;
export 'src/services/artist_service.dart' show ArtistService;
export 'src/services/capture_service.dart' show CaptureService;
export 'src/services/payment_service.dart' show PaymentService;
export 'src/services/notification_service.dart'
    show NotificationService, NotificationType;

// Export Core Models
export 'src/models/index.dart'; // This will export all models through the barrel file
export 'src/models/types/index.dart'; // Export all type definitions
export 'src/models/event_model.dart' show EventModel;
export 'src/models/capture_model.dart' show CaptureModel;
export 'src/models/user_type.dart' show UserType;
export 'src/models/subscription_tier.dart' show SubscriptionTier;
export 'src/models/payment_method_model.dart' show PaymentMethodModel;

// Export Core Widgets
export 'src/widgets/artbeat_button.dart';
export 'src/widgets/artbeat_input.dart';
export 'src/widgets/artbeat_app_header.dart';
export 'src/widgets/artbeat_drawer.dart';
export 'src/widgets/artbeat_drawer_items.dart';
export 'src/widgets/art_capture_warning_dialog.dart';
export 'src/widgets/loading_screen.dart';
export 'src/widgets/profile_tab_interface.dart';
export 'src/widgets/featured_content_row_widget.dart';
export 'src/widgets/network_error_widget.dart';

// Export Core Widget Utils
export 'src/widgets/filter/index.dart';

// Export Core Utils
export 'src/utils/color_extensions.dart';
export 'src/utils/connectivity_utils.dart';
export 'src/utils/date_utils.dart';
export 'src/utils/validators.dart';

// Export Screens
export 'src/screens/splash_screen.dart' show SplashScreen;
export 'src/screens/dashboard_screen.dart' show DashboardScreen;
