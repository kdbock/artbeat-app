import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/artbeat_colors.dart';
import '../providers/messaging_provider.dart';

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
  final double? titleFontSize;

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
    this.titleFontSize,
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
          icon: const Icon(Icons.arrow_back),
          onPressed: _toggleSearch,
          tooltip: 'Back',
        ),

        // Search input field
        Expanded(
          child: Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: const InputDecoration(
                hintText: 'Search artists, artwork...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  // Handle search
                  widget.onSearchPressed?.call();
                }
              },
            ),
          ),
        ),

        // Voice search or clear button
        IconButton(
          icon: Icon(
            _searchController.text.isEmpty ? Icons.mic : Icons.clear,
            color: ArtbeatColors.textSecondary,
          ),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              // Voice search functionality
              HapticFeedback.lightImpact();
              _startVoiceSearch();
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
            fontSize: widget.titleFontSize ?? 24,
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
    final List<Widget> actions = <Widget>[];

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

    // Messaging icon with unread dot
    actions.add(_buildMessagingIcon());

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
      // Adding custom actions
      actions.addAll(widget.actions!);
    }

    return actions;
  }

  Widget _buildMessagingIcon() {
    return Consumer<MessagingProvider>(
      builder: (context, messagingProvider, child) {
        debugPrint(
          'MessagingIcon: hasUnread=${messagingProvider.hasUnreadMessages}, count=${messagingProvider.unreadCount}, initialized=${messagingProvider.isInitialized}, hasError=${messagingProvider.hasError}',
        );

        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.message_outlined,
                color: messagingProvider.hasError
                    ? ArtbeatColors.error.withValues(alpha: 0.6)
                    : widget.foregroundColor ?? ArtbeatColors.textPrimary,
              ),
              onPressed: () async {
                // Navigate to messaging and refresh count when returning
                await Navigator.pushNamed(context, '/messaging');
                // Refresh the unread count when returning from messaging
                if (context.mounted) {
                  final provider = context.read<MessagingProvider>();
                  provider.refreshUnreadCount();
                }
              },
              tooltip: messagingProvider.hasError
                  ? 'Messages (Error loading count)'
                  : 'Messages',
            ),
            // Loading indicator for uninitialized state
            if (!messagingProvider.isInitialized && !messagingProvider.hasError)
              Positioned(
                right: 8,
                top: 8,
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.foregroundColor ?? ArtbeatColors.textPrimary,
                    ),
                  ),
                ),
              ),
            // Unread message indicator
            if (messagingProvider.isInitialized &&
                !messagingProvider.hasError &&
                messagingProvider.hasUnreadMessages)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: ArtbeatColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    messagingProvider.unreadCount > 99
                        ? '99+'
                        : messagingProvider.unreadCount.toString(),
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
        );
      },
    );
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

  void _startVoiceSearch() {
    // Show voice search dialog
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic, color: Colors.red),
            SizedBox(width: 8),
            Text('Voice Search'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Listening...'),
            SizedBox(height: 8),
            Text(
              'Voice search is coming soon!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
