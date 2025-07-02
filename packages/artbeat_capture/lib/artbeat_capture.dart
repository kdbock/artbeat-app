library artbeat_capture;

// Re-export the model from core
export 'package:artbeat_core/artbeat_core.dart' show CaptureModel;

// Screens and services
export 'src/screens/capture_screen.dart';
export 'src/screens/capture_upload_screen.dart';
export 'src/screens/capture_detail_screen.dart';
export 'src/services/capture_service.dart';
export 'src/services/storage_service.dart';
export 'src/services/camera_service.dart';

// Widgets
export 'src/widgets/captures_grid.dart';
export 'src/widgets/artist_search_dialog.dart';
export 'src/widgets/map_picker_dialog.dart';
