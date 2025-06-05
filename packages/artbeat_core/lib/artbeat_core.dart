// artbeat_core entry point

/// ARTbeat Core package with shared functionality
library artbeat_core;

// Export Firebase configuration
export 'src/firebase/secure_firebase_config.dart';

// Export models and types
export 'src/models/subscription_tier.dart';
export 'src/models/notification_model.dart';
export 'src/models/artist_profile_model.dart';
export 'src/models/user_model.dart';
export 'src/models/favorite_model.dart';
export 'src/models/payment_method_model.dart';
export 'src/models/gift_model.dart';

// Export services
export 'src/services/user_service.dart';
export 'src/services/notification_service.dart' hide NotificationType;
export 'src/services/payment_service.dart' show PaymentService;
export 'src/services/firebase_diagnostic_service.dart';
export 'src/services/subscription_service.dart';
export 'src/services/navigation_service.dart';
export 'src/services/connectivity_service.dart';

// Export utils
export 'src/utils/location_utils.dart' hide SimpleLatLng;
export 'src/utils/connectivity_utils.dart';
export 'src/utils/coordinate_validator.dart'
    show CoordinateValidator, SimpleLatLng;
export 'src/utils/app_config.dart';

// Export widgets and screens
export 'src/widgets/loading_screen.dart';
export 'src/widgets/profile_tab_interface.dart';
export 'src/screens/dashboard_screen.dart';
export 'src/screens/splash_screen.dart';
