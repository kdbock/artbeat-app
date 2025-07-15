import 'package:flutter/material.dart';
import '../constants/routes.dart';
import '../screens/screens.dart';
import '../models/models.dart';

/// Art walk module route configuration
class ArtWalkRouteConfig {
  static Map<String, Widget Function(BuildContext)> routes = {
    ArtWalkRoutes.map: (_) => const ArtWalkMapScreen(),
    ArtWalkRoutes.list: (_) => const ArtWalkListScreen(),
    ArtWalkRoutes.dashboard: (_) => const ArtWalkDashboardScreen(),
    ArtWalkRoutes.myCaptures: (_) => const MyCapturesScreen(),
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

      case ArtWalkRoutes.enhancedCreate:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EnhancedArtWalkCreateScreen(
            artWalkId: args?['artWalkId'] as String?,
            artWalkToEdit: args?['artWalk'] as ArtWalkModel?,
          ),
        );

      case ArtWalkRoutes.enhancedExperience:
        final args = settings.arguments as Map<String, dynamic>?;
        final artWalkId = args?['artWalkId'] as String?;
        final artWalk = args?['artWalk'] as ArtWalkModel?;
        if (artWalkId == null || artWalk == null) {
          return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text('Art walk not found'))),
          );
        }
        return MaterialPageRoute(
          builder: (_) => EnhancedArtWalkExperienceScreen(
            artWalkId: artWalkId,
            artWalk: artWalk,
          ),
        );

      default:
        return null;
    }
  }
}
