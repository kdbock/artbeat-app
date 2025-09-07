import 'package:flutter/material.dart';

/// Universal ARTbeat Header Widget
/// Provides consistent, color-coded headers across all modules
class UniversalArtbeatHeader extends StatelessWidget {
  final String moduleName;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double height;
  final bool useGradient;

  const UniversalArtbeatHeader({
    super.key,
    required this.moduleName,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.height = 80.0,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getModuleColorScheme(moduleName);
    final theme = Theme.of(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: useGradient && colorScheme.gradient != null
            ? colorScheme.gradient
            : LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Back Button
              if (showBackButton)
                IconButton(
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),

              // Module Icon and Title Section
              Expanded(
                child: Row(
                  children: [
                    // Module Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.onPrimary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getModuleIcon(moduleName),
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title and Subtitle
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimary.withValues(
                                  alpha: 0.8,
                                ),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              ...?actions,
            ],
          ),
        ),
      ),
    );
  }

  ModuleColorScheme _getModuleColorScheme(String moduleName) {
    return moduleColorSchemes[moduleName] ??
        moduleColorSchemes['artbeat_core']!;
  }

  IconData _getModuleIcon(String moduleName) {
    return moduleIcons[moduleName] ?? Icons.apps;
  }
}

/// Color scheme definition for each module
class ModuleColorScheme {
  final Color primary;
  final Color secondary;
  final Color onPrimary;
  final Gradient? gradient;

  const ModuleColorScheme({
    required this.primary,
    required this.secondary,
    required this.onPrimary,
    this.gradient,
  });
}

/// Universal color schemes for all ARTbeat modules
final Map<String, ModuleColorScheme> moduleColorSchemes = {
  'artbeat_admin': const ModuleColorScheme(
    primary: Color(0xFF1976D2), // Blue
    secondary: Color(0xFF4CAF50), // Green
    onPrimary: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFF1976D2), Color(0xFF4CAF50)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),

  'artbeat_ads': const ModuleColorScheme(
    primary: Color(0xFFD2B48C), // Tan
    secondary: Color(0xFF9C27B0), // Purple
    onPrimary: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFFD2B48C), Color(0xFF9C27B0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),

  'artbeat_art_walk': const ModuleColorScheme(
    primary: Color(0xFF009688), // Teal
    secondary: Color(0xFFFF9800), // Peach/Orange
    onPrimary: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFF009688), Color(0xFFFF9800)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),

  'artbeat_artwork': const ModuleColorScheme(
    primary: Color(0xFFE91E63), // Pink
    secondary: Color(0xFF2196F3), // Blue
    onPrimary: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFFE91E63), Color(0xFF2196F3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),

  'artbeat_artist': const ModuleColorScheme(
    primary: Color(0xFF9C27B0), // Violet/Purple
    secondary: Color(0xFFFFEB3B), // Yellow
    onPrimary: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFF9C27B0), Color(0xFFFFEB3B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),

  'artbeat_auth': const ModuleColorScheme(
    primary: Colors.transparent,
    secondary: Colors.transparent,
    onPrimary: Colors.transparent,
    // No header for auth module
  ),

  'artbeat_capture': const ModuleColorScheme(
    primary: Color(0xFF2E7D32), // Hunter Green
    secondary: Color(0xFFE1BEE7), // Lavender
    onPrimary: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFF2E7D32), Color(0xFFE1BEE7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),

  'artbeat_community': const ModuleColorScheme(
    primary: Color(0xFF880E4F), // Burgundy
    secondary: Color(0xFF4CAF50), // Green
    onPrimary: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFF880E4F), Color(0xFF4CAF50)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),

  'artbeat_profile': const ModuleColorScheme(
    primary: Color(0xFFFFD700), // Gold
    secondary: Color(0xFF9C27B0), // Purple
    onPrimary: Colors.black87,
    gradient: LinearGradient(
      colors: [Color(0xFFFFD700), Color(0xFF9C27B0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),

  'artbeat_messaging': const ModuleColorScheme(
    primary: Color(0xFFFF4081), // Multicolor start - Pink
    secondary: Color(0xFF3F51B5), // Blue
    onPrimary: Colors.white,
    gradient: LinearGradient(
      colors: [
        Color(0xFFFF4081), // Pink
        Color(0xFF3F51B5), // Blue
        Color(0xFF4CAF50), // Green
        Color(0xFFFF9800), // Orange
        Color(0xFF9C27B0), // Purple
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),

  'artbeat_core': const ModuleColorScheme(
    primary: Color(0xFF9C27B0), // Purple
    secondary: Color(0xFF4CAF50), // Green
    onPrimary: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFF9C27B0), Color(0xFF4CAF50)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),

  'artbeat_events': const ModuleColorScheme(
    primary: Color(0xFFF44336), // Red
    secondary: Color(0xFFB0BEC5), // Silver/Grey
    onPrimary: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFFF44336), Color(0xFFB0BEC5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),

  'artbeat_settings': const ModuleColorScheme(
    primary: Color(0xFFFF9800), // Orange
    secondary: Color(0xFF4DB6AC), // Mint Green
    onPrimary: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFFFF9800), Color(0xFF4DB6AC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
};

/// Module icons mapping
final Map<String, IconData> moduleIcons = {
  'artbeat_admin': Icons.admin_panel_settings,
  'artbeat_ads': Icons.campaign,
  'artbeat_art_walk': Icons.directions_walk,
  'artbeat_artwork': Icons.palette,
  'artbeat_artist': Icons.brush,
  'artbeat_auth': Icons.lock,
  'artbeat_capture': Icons.camera,
  'artbeat_community': Icons.people,
  'artbeat_profile': Icons.person,
  'artbeat_messaging': Icons.message,
  'artbeat_core': Icons.apps,
  'artbeat_events': Icons.event,
  'artbeat_settings': Icons.settings,
};
