import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/artbeat_colors.dart';

/// Enhanced Bottom Navigation with improved accessibility and design
///
/// Key improvements:
/// - Better touch targets and accessibility
/// - Improved visual feedback and animations
/// - Semantic labels for screen readers
/// - Haptic feedback for better UX
/// - Dynamic theming support
/// - Badge support for notifications
/// - Improved capture button design
class EnhancedBottomNav extends StatefulWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final bool showLabels;
  final List<BottomNavItem> items;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? elevation;

  const EnhancedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = true,
    this.items = const [],
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.elevation,
  });

  @override
  State<EnhancedBottomNav> createState() => _EnhancedBottomNavState();
}

class _EnhancedBottomNavState extends State<EnhancedBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    final itemCount = _getDefaultItems().length;
    _controllers = List.generate(
      itemCount,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Set initial animation state
    if (widget.currentIndex < _controllers.length) {
      _controllers[widget.currentIndex].value = 1.0;
    }
  }

  @override
  void didUpdateWidget(EnhancedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Animate out old selection
      if (oldWidget.currentIndex < _controllers.length) {
        _controllers[oldWidget.currentIndex].reverse();
      }
      // Animate in new selection
      if (widget.currentIndex < _controllers.length) {
        _controllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<BottomNavItem> _getDefaultItems() {
    return widget.items.isNotEmpty ? widget.items : [
      BottomNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        semanticLabel: 'Home - Main dashboard',
      ),
      BottomNavItem(
        icon: Icons.map_outlined,
        activeIcon: Icons.map_rounded,
        label: 'Art Walk',
        semanticLabel: 'Art Walk - Explore art locations',
      ),
      BottomNavItem(
        icon: Icons.camera_alt_outlined,
        activeIcon: Icons.camera_alt_rounded,
        label: 'Capture',
        semanticLabel: 'Capture - Take photos of art',
        isSpecial: true,
      ),
      BottomNavItem(
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        label: 'Community',
        semanticLabel: 'Community - Connect with other users',
        badgeCount: 3,
      ),
      BottomNavItem(
        icon: Icons.event_outlined,
        activeIcon: Icons.event_rounded,
        label: 'Events',
        semanticLabel: 'Events - Discover art events',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _getDefaultItems();
    
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildNavItem(context, index, item);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, BottomNavItem item) {
    final isActive = widget.currentIndex == index;
    final activeColor = widget.activeColor ?? ArtbeatColors.primaryPurple;
    final inactiveColor = widget.inactiveColor ?? ArtbeatColors.textSecondary;

    if (item.isSpecial) {
      return _buildSpecialButton(context, index, item, isActive);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTap(index),
        child: Semantics(
          label: item.semanticLabel ?? item.label,
          selected: isActive,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                final animValue = _animations[index].value;
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? activeColor.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: Color.lerp(inactiveColor, activeColor, animValue),
                            size: 24 + (animValue * 2),
                          ),
                        ),
                        
                        // Badge
                        if (item.badgeCount > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: ArtbeatColors.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                item.badgeCount > 99 ? '99+' : item.badgeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Label
                    if (widget.showLabels) ...[
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: Color.lerp(inactiveColor, activeColor, animValue),
                          letterSpacing: 0.2,
                        ),
                        child: Text(
                          item.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialButton(BuildContext context, int index, BottomNavItem item, bool isActive) {
    return GestureDetector(
      onTap: () => _handleTap(index),
      child: Semantics(
        label: item.semanticLabel ?? item.label,
        selected: isActive,
        child: AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            final animValue = _animations[index].value;
            final scale = 1.0 + (animValue * 0.1);
            
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ArtbeatColors.primaryPurple,
                      ArtbeatColors.primaryGreen,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 12 + (animValue * 8),
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: ArtbeatColors.primaryGreen.withValues(alpha: 0.2),
                      blurRadius: 8 + (animValue * 4),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.3, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: Colors.white,
                    size: 28 + (animValue * 4),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleTap(int index) {
    if (index != widget.currentIndex) {
      HapticFeedback.lightImpact();
      widget.onTap(index);
    }
  }
}

/// Data class for bottom navigation items
class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? semanticLabel;
  final bool isSpecial;
  final int badgeCount;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.semanticLabel,
    this.isSpecial = false,
    this.badgeCount = 0,
  });
}