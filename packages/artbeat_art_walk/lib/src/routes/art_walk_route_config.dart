import 'package:flutter/material.dart';
import '../constants/routes.dart';
import '../screens/screens.dart';
import '../models/models.dart';

/// Art walk module route configuration
class ArtWalkRouteConfig {
  static Map<String, Widget Function(BuildContext)> routes = {
    ArtWalkRoutes.map: (_) => const ArtWalkMapScreen(),
    ArtWalkRoutes.list: (_) => const ArtWalkListScreen(),
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case ArtWalkRoutes.detail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ArtWalkDetailScreen(walkId: args['walkId'] as String),
        );

      case ArtWalkRoutes.experience:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ArtWalkExperienceScreen(
            artWalkId: args['artWalkId'] as String,
            artWalk: args['artWalk'] as ArtWalkModel,
          ),
        );

      case ArtWalkRoutes.create:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CreateArtWalkScreen(
            artWalkId: args?['artWalkId'] as String?,
            artWalkToEdit: args?['artWalk'] as ArtWalkModel?,
          ),
        );

      case ArtWalkRoutes.edit:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ArtWalkEditScreen(
            artWalkId: args['walkId'] as String,
            artWalk: args['artWalk'] as ArtWalkModel?,
          ),
        );

      default:
        return null;
    }
  }
}
