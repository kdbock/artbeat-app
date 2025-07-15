import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/artbeat_colors.dart';

/// Enhanced Universal Header with improved visual hierarchy and user experience
///
/// Key improvements:
/// - Cleaner visual hierarchy with better spacing
/// - More prominent branding while maintaining functionality
/// - Improved accessibility with semantic labels
/// - Consistent interaction patterns
/// - Better mobile-first design approach
/// - Enhanced search experience
/// - Streamlined developer tools
class EnhancedUniversalHeader extends StatefulWidget
    implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final bool showSearch;
  final bool showDeveloperTools;
  final bool showBackButton;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onDeveloperPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool hasNotifications;
  final int notificationCount;

  const EnhancedUniversalHeader({
    super.key,
    this.title,
    this.showLogo = true,
    this.showSearch = true,
    this.showDeveloperTools = false,
    this.showBackButton = false,
    this.onMenuPressed,
    this.onSearchPressed,
    this.onDeveloperPressed,
    this.onProfilePressed,
    this.onBackPressed,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.hasNotifications = false,
    this.notificationCount = 0,
  });

  @override
  State<EnhancedUniversalHeader> createState() =>
      _EnhancedUniversalHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
}

class _EnhancedUniversalHeaderState extends State<EnhancedUniversalHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
    });

    if (_isSearchActive) {
      _animationController.forward();
      _searchFocusNode.requestFocus();
    } else {
      _animationController.reverse();
      _searchController.clear();
      _searchFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.transparent,
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: kToolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isSearchActive ? _buildSearchBar() : _buildNormalHeader(),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalHeader() {
    return Row(
      children: [
        // Leading: Menu or Back Button
        _buildLeadingButton(),

        // Title/Logo Section
        Expanded(child: _buildTitleSection()),

        // Actions Section
        ..._buildActionButtons(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        // Back button from search
        IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: widget.foregroundColor ?? ArtbeatColors.textPrimary,
          ),
          onPressed: _toggleSearch,
          tooltip: 'Close search',
        ),

        // Search input
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: ArtbeatColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: const InputDecoration(
                  hintText: 'Search artists, artwork, events...',
                  hintStyle: TextStyle(
                    color: ArtbeatColors.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: ArtbeatColors.primaryPurple,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                style: const TextStyle(
                  color: ArtbeatColors.textPrimary,
                  fontSize: 14,
                ),
                onSubmitted: (query) {
                  if (query.isNotEmpty) {
                    // Navigate to search results page with query
                    Navigator.pushNamed(
                      context,
                      '/search/results',
                      arguments: {'query': query},
                    );
                    _toggleSearch();
                  }
                },
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Clear/Search button
        IconButton(
          icon: Icon(
            _searchController.text.isEmpty ? Icons.mic : Icons.clear,
            color: ArtbeatColors.textSecondary,
          ),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              // Voice search functionality
              HapticFeedback.lightImpact();
              // TODO: Implement voice search
            } else {
              _searchController.clear();
            }
          },
          tooltip: _searchController.text.isEmpty ? 'Voice search' : 'Clear',
        ),
      ],
    );
  }

  Widget _buildLeadingButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: widget.showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: widget.foregroundColor ?? ArtbeatColors.textPrimary,
              ),
              onPressed:
                  widget.onBackPressed ?? () => Navigator.maybePop(context),
              tooltip: 'Back',
            )
          : IconButton(
              icon: Icon(
                Icons.menu,
                color: widget.foregroundColor ?? ArtbeatColors.textPrimary,
              ),
              onPressed: widget.onMenuPressed ?? () => _openDrawer(),
              tooltip: 'Menu',
            ),
    );
  }

  Widget _buildTitleSection() {
    if (widget.showLogo) {
      return Center(
        child: Container(
          height: 36,
          constraints: const BoxConstraints(maxWidth: 200),
          child: Image.asset(
            'assets/images/artbeat_header.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Text(
                widget.title ?? 'ARTbeat',
                style: TextStyle(
                  color: widget.foregroundColor ?? ArtbeatColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
      );
    } else if (widget.title != null) {
      return Center(
        child: Text(
          widget.title!,
          style: TextStyle(
            color: widget.foregroundColor ?? ArtbeatColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  List<Widget> _buildActionButtons() {
    final actions = <Widget>[];

    // Search button
    if (widget.showSearch) {
      actions.add(
        IconButton(
          icon: Icon(
            Icons.search,
            color: widget.foregroundColor ?? ArtbeatColors.textPrimary,
          ),
          onPressed: _toggleSearch,
          tooltip: 'Search',
        ),
      );
    }

    // Profile/Artist discovery with notification badge
    actions.add(
      Stack(
        children: [
          IconButton(
            icon: Icon(
              Icons.person_outline,
              color: widget.foregroundColor ?? ArtbeatColors.textPrimary,
            ),
            onPressed: widget.onProfilePressed ?? () => _showProfileMenu(),
            tooltip: 'Profile & Discovery',
          ),
          if (widget.hasNotifications)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: ArtbeatColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  widget.notificationCount > 99
                      ? '99+'
                      : widget.notificationCount.toString(),
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
    );

    // Developer tools (if enabled)
    if (widget.showDeveloperTools) {
      actions.add(
        IconButton(
          icon: Icon(
            Icons.developer_mode,
            color: widget.foregroundColor ?? ArtbeatColors.textSecondary,
          ),
          onPressed: widget.onDeveloperPressed ?? () => _showDeveloperTools(),
          tooltip: 'Developer Tools',
        ),
      );
    }

    // Additional custom actions
    if (widget.actions != null) {
      actions.addAll(widget.actions!);
    }

    return actions;
  }

  void _openDrawer() {
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.hasDrawer) {
      scaffoldState.openDrawer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Navigation menu coming soon!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: ArtbeatColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.explore,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discover & Connect',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Find artists, explore art, join the community',
                            style: TextStyle(
                              fontSize: 14,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Menu items
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildMenuTile(
                      icon: Icons.person_search,
                      title: 'Find Artists',
                      subtitle: 'Discover local and featured artists',
                      color: ArtbeatColors.primaryPurple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artist/search');
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.palette,
                      title: 'Browse Artwork',
                      subtitle: 'Explore art collections and galleries',
                      color: ArtbeatColors.primaryGreen,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artwork/browse');
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.location_on,
                      title: 'Local Scene',
                      subtitle: 'Art events and spaces near you',
                      color: ArtbeatColors.error,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/local');
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.trending_up,
                      title: 'Trending',
                      subtitle: 'Popular artists and trending art',
                      color: ArtbeatColors.warning,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/trending');
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.account_circle,
                      title: 'My Profile',
                      subtitle: 'View and edit your profile',
                      color: ArtbeatColors.info,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: ArtbeatColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeveloperTools() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.code, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Developer Tools',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildDeveloperTile(
              icon: Icons.feedback,
              title: 'Submit Feedback',
              subtitle: 'Report bugs or suggest improvements',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/feedback');
              },
            ),

            _buildDeveloperTile(
              icon: Icons.admin_panel_settings,
              title: 'Admin Panel',
              subtitle: 'Manage feedback and system settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/developer-feedback-admin');
              },
            ),

            _buildDeveloperTile(
              icon: Icons.info,
              title: 'System Info',
              subtitle: 'View app version and system details',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/system/info');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: ArtbeatColors.textSecondary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: ArtbeatColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
