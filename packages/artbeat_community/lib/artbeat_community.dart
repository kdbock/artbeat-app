/// ARTbeat Community package with social and community functionality
library artbeat_community;

// Export all screens via the barrel file
export 'screens/screens.dart';

// Models
export 'models/models.dart';
export 'models/post_model.dart';
export 'models/comment_model.dart';
export 'models/artwork_model.dart';
export 'models/studio_model.dart';
export 'models/gift_model_export.dart'; // Use export file to avoid conflicts
export 'models/direct_commission_model.dart';
export 'models/sponsor_model.dart';

// Services
export 'services/services.dart';
export 'services/community_service.dart';
export 'services/storage_service.dart';
export 'services/direct_commission_service.dart';
export 'services/stripe_service.dart';

// Widgets
export 'widgets/widgets.dart';
export 'widgets/post_card.dart';
export 'widgets/feedback_thread_widget.dart';
export 'widgets/applause_button.dart';
export 'widgets/avatar_widget.dart';
export 'widgets/artwork_card_widget.dart';
export 'widgets/gift_card_widget.dart';
export 'widgets/group_feed_widget.dart';
export 'widgets/group_post_card.dart';
export 'widgets/create_post_fab.dart';
export 'widgets/artist_list_widget.dart';
export 'widgets/community_drawer.dart';

// Controllers
export 'controllers/controllers.dart';
