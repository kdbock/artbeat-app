// artbeat_core entry point

/// ARTbeat Core package with shared functionality
library artbeat_core;

// Export Firebase configuration
export 'src/firebase/secure_firebase_config.dart';
export 'src/firebase_options.dart';

// Export models and types
export 'src/models/models.dart';

// Export services
export 'src/services/services.dart';
export 'src/services/subscription_service.dart';
export 'src/services/subscription_plan_validator.dart';
export 'src/services/subscription_validation_service.dart';

// Export utils
export 'src/utils/location_utils.dart';
export 'src/utils/connectivity_utils.dart';
export 'src/utils/coordinate_validator.dart'
    show CoordinateValidator, SimpleLatLng;
export 'src/utils/app_config.dart';

// Export widgets and screens
export 'src/widgets/loading_screen.dart';
export 'src/widgets/profile_tab_interface.dart';
export 'src/screens/home_tab.dart' show HomeTab;
export 'src/screens/splash_screen.dart';
export 'src/screens/dashboard_screen.dart';

// Export theme and components
export 'theme/artbeat_colors.dart';
export 'theme/artbeat_components.dart';
export 'theme/artbeat_theme.dart';
export 'theme/artbeat_typography.dart';
export 'widgets/artbeat_button.dart';
export 'widgets/artbeat_input.dart';
export 'widgets/artbeat_app_header.dart';
export 'widgets/artbeat_drawer.dart';
export 'widgets/artbeat_drawer_items.dart';
export 'src/widgets/art_capture_warning_dialog.dart';
