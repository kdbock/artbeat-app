import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import '../theme/artbeat_colors.dart';
import '../providers/messaging_provider.dart';
import 'enhanced_profile_menu.dart';

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
  final void Function(String)? onSearchPressed;
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
  final Gradient? backgroundGradient;
  final Gradient? titleGradient;
  final GlobalKey<ScaffoldState>? scaffoldKey;

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
    this.backgroundGradient,
    this.titleGradient,
    this.scaffoldKey,
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

  // Search results
  List<HeaderSearchResult> _searchResults = [];
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Listen for focus changes to hide overlay when search loses focus
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _removeOverlay();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
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
        gradient: widget.backgroundGradient,
        color: widget.backgroundGradient == null
            ? (widget.backgroundColor ?? Colors.transparent)
            : null,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        // Leading: Menu or Back Button
        _buildLeadingButton(),

        // Title/Logo Section
        Expanded(child: _buildTitleSection()),

        // Actions Section - use Wrap for better overflow handling
        SizedBox(
          width: 200,
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            runSpacing: 4,
            children: _buildActionButtons(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        // Back button from search
        IconButton(
          icon: const Icon(Icons.arrow_back, color: ArtbeatColors.headerText),
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
              onChanged: (value) {
                _debouncedSearch(value);
              },
              onSubmitted: (value) {
                if (value.isNotEmpty && _searchResults.isNotEmpty) {
                  _handleResultTap(_searchResults.first);
                }
              },
            ),
          ),
        ),

        // Voice search or clear button
        IconButton(
          icon: Icon(
            _searchController.text.isEmpty ? Icons.mic : Icons.clear,
            color: ArtbeatColors.headerText,
          ),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              // Voice search functionality
              HapticFeedback.lightImpact();
              _startVoiceSearch();
            } else {
              _searchController.clear();
              _clearSearch();
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
                color: widget.foregroundColor ?? ArtbeatColors.headerText,
              ),
              onPressed:
                  widget.onBackPressed ?? () => Navigator.maybePop(context),
              tooltip: 'Back',
            )
          : IconButton(
              icon: Icon(
                Icons.menu,
                color: widget.foregroundColor ?? ArtbeatColors.headerText,
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
          child: Text(
            widget.title ?? 'ARTbeat',
            style: TextStyle(
              color: widget.foregroundColor ?? ArtbeatColors.headerText,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (widget.title != null) {
      final textStyle = TextStyle(
        color: widget.titleGradient == null
            ? (widget.foregroundColor ?? ArtbeatColors.headerText)
            : null,
        fontWeight: FontWeight.w900,
        fontSize: widget.titleFontSize ?? 24,
        letterSpacing: 1.2,
        shadows: widget.titleGradient == null
            ? [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ]
            : null,
      );

      final textWidget = Text(
        widget.title!,
        style: textStyle,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      );

      return Center(
        child: widget.titleGradient != null
            ? ShaderMask(
                shaderCallback: (bounds) => widget.titleGradient!.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                child: textWidget,
              )
            : textWidget,
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
            color: widget.foregroundColor ?? ArtbeatColors.headerText,
          ),
          onPressed: _toggleSearch,
          tooltip: 'Search',
        ),
      );
    }

    // Messaging icon with unread dot
    actions.add(_buildMessagingIcon());

    // Profile icon
    actions.add(_buildProfileIcon());

    // Developer tools (if enabled)
    if (widget.showDeveloperTools) {
      actions.add(
        IconButton(
          icon: Icon(
            Icons.developer_mode,
            color: widget.foregroundColor ?? ArtbeatColors.headerText,
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
    // In test environment, return a simple icon without Consumer
    if (kDebugMode || Platform.environment.containsKey('FLUTTER_TEST')) {
      return IconButton(
        icon: Icon(
          Icons.message_outlined,
          color: widget.foregroundColor ?? ArtbeatColors.headerText,
        ),
        onPressed: () async {
          // Navigate to messaging and refresh count when returning
          await Navigator.pushNamed(context, '/messaging');
        },
        tooltip: 'Messages',
      );
    }

    return Consumer<MessagingProvider>(
      builder: (context, messagingProvider, child) {
        // Only log when there are actual changes to avoid spam
        if (messagingProvider.hasUnreadMessages || messagingProvider.hasError) {
          debugPrint(
            'MessagingIcon: hasUnread=${messagingProvider.hasUnreadMessages}, count=${messagingProvider.unreadCount}, initialized=${messagingProvider.isInitialized}, hasError=${messagingProvider.hasError}',
          );
        }

        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.message_outlined,
                color: messagingProvider.hasError
                    ? ArtbeatColors.error.withValues(alpha: 0.6)
                    : widget.foregroundColor ?? ArtbeatColors.headerText,
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

  Widget _buildProfileIcon() {
    return IconButton(
      icon: Icon(
        Icons.account_circle,
        color: widget.foregroundColor ?? ArtbeatColors.headerText,
      ),
      onPressed: widget.onProfilePressed ?? () => _showProfileMenu(),
      tooltip: 'Profile',
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EnhancedProfileMenu(),
    );
  }

  void _openDrawer() {
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.hasDrawer) {
      scaffoldState.openDrawer();
    } else {
      // Try alternative approach - look for Scaffold in parent contexts
      BuildContext? ctx = context;
      ScaffoldState? foundScaffold;

      // Try up to 5 levels up in the widget tree
      for (int i = 0; i < 5 && ctx != null; i++) {
        foundScaffold = Scaffold.maybeOf(ctx);
        if (foundScaffold != null && foundScaffold.hasDrawer) {
          foundScaffold.openDrawer();
          return;
        }
        // Get the element and try to find parent
        final element = ctx as Element?;
        ctx = element?.findAncestorWidgetOfExactType<Scaffold>() != null
            ? ctx
            : null;
      }

      // If still not found, show debug info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Drawer not found. Scaffold: ${scaffoldState != null}, hasDrawer: ${scaffoldState?.hasDrawer ?? false}',
          ),
          duration: const Duration(seconds: 3),
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

  void _debouncedSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    try {
      final results = await _searchDatabase(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
        });
        _showSearchOverlay();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<HeaderSearchResult>> _searchDatabase(String query) async {
    final List<HeaderSearchResult> results = [];
    final lowerQuery = query.toLowerCase();

    try {
      // Search users/artists
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .limit(30)
          .get();

      for (final doc in usersQuery.docs) {
        final data = doc.data();
        final fullName = data['fullName'] as String? ?? '';
        final username = data['username'] as String? ?? '';
        final profileImageUrl = data['profileImageUrl'] as String?;

        // Check if query matches any part of the full name or username
        final fullNameLower = fullName.toLowerCase();
        final usernameLower = username.toLowerCase();

        bool matches = false;

        // Check for exact word matches (like "Kelly" in "Kristy Kelly")
        if (fullNameLower.contains(lowerQuery) ||
            usernameLower.contains(lowerQuery)) {
          matches = true;
        }

        // Check for word boundary matches
        final queryWords = lowerQuery.split(' ');
        final nameWords = fullNameLower.split(' ');

        for (final queryWord in queryWords) {
          if (queryWord.isNotEmpty) {
            for (final nameWord in nameWords) {
              if (nameWord.startsWith(queryWord) ||
                  nameWord.contains(queryWord)) {
                matches = true;
                break;
              }
            }
            if (matches) break;
          }
        }

        if (matches) {
          results.add(
            HeaderSearchResult(
              id: doc.id,
              title: fullName.isNotEmpty ? fullName : username,
              subtitle: username.isNotEmpty ? '@$username' : '',
              imageUrl: profileImageUrl,
              type: HeaderSearchResultType.artist,
              data: data,
            ),
          );
        }

        // Limit user results
        if (results
                .where((r) => r.type == HeaderSearchResultType.artist)
                .length >=
            2)
          break;
      }

      // Search captures/artworks using CaptureService
      try {
        final captureService = CaptureService();
        final captures = await captureService.getAllCaptures(limit: 50);

        for (final capture in captures) {
          final title = capture.title ?? '';
          final artistName = capture.artistName ?? '';
          final description = capture.description ?? '';
          final imageUrl = capture.imageUrl;
          final tags = capture.tags ?? [];

          // Check if query matches title, artist name, description, or tags
          final titleLower = title.toLowerCase();
          final artistNameLower = artistName.toLowerCase();
          final descriptionLower = description.toLowerCase();
          final tagsLower = tags.map((tag) => tag.toLowerCase()).toList();

          bool matches = false;

          // Check title, artist name, and description
          if (titleLower.contains(lowerQuery) ||
              artistNameLower.contains(lowerQuery) ||
              descriptionLower.contains(lowerQuery)) {
            matches = true;
          }

          // Check tags
          if (!matches) {
            for (final tag in tagsLower) {
              if (tag.contains(lowerQuery)) {
                matches = true;
                break;
              }
            }
          }

          if (matches) {
            results.add(
              HeaderSearchResult(
                id: capture.id,
                title: title.isNotEmpty ? title : 'Untitled Capture',
                subtitle: artistName.isNotEmpty
                    ? 'by $artistName'
                    : 'Captured Art',
                imageUrl: imageUrl,
                type: HeaderSearchResultType.artwork,
                data: {
                  'title': title,
                  'artistName': artistName,
                  'description': description,
                  'imageUrl': imageUrl,
                  'tags': tags,
                  'userId': capture.userId,
                  'capturedAt': capture.createdAt.toIso8601String(),
                },
              ),
            );
          }

          // Limit capture results
          if (results
                  .where((r) => r.type == HeaderSearchResultType.artwork)
                  .length >=
              2)
            break;
        }
      } catch (e) {
        debugPrint('Error searching captures: $e');
      }

      // Search artist profiles
      final artistProfilesQuery = await FirebaseFirestore.instance
          .collection('artist_profiles')
          .limit(30)
          .get();

      for (final doc in artistProfilesQuery.docs) {
        final data = doc.data();
        final artistName = data['artistName'] as String? ?? '';
        final bio = data['bio'] as String? ?? '';
        final profileImageUrl = data['profileImageUrl'] as String?;
        final tags = data['tags'] as List<dynamic>? ?? [];

        // Check if query matches artist name, bio, or tags
        final artistNameLower = artistName.toLowerCase();
        final bioLower = bio.toLowerCase();
        final tagsLower = tags
            .map((tag) => tag.toString().toLowerCase())
            .toList();

        bool matches = false;

        // Check artist name and bio
        if (artistNameLower.contains(lowerQuery) ||
            bioLower.contains(lowerQuery)) {
          matches = true;
        }

        // Check tags
        if (!matches) {
          for (final tag in tagsLower) {
            if (tag.contains(lowerQuery)) {
              matches = true;
              break;
            }
          }
        }

        if (matches) {
          results.add(
            HeaderSearchResult(
              id: doc.id,
              title: artistName.isNotEmpty ? artistName : 'Artist Profile',
              subtitle: 'Artist Profile',
              imageUrl: profileImageUrl,
              type: HeaderSearchResultType.artist,
              data: data,
            ),
          );
        }

        // Limit artist profile results
        if (results
                .where((r) => r.type == HeaderSearchResultType.artist)
                .length >=
            3)
          break;
      }

      // Search art walks
      final artWalksQuery = await FirebaseFirestore.instance
          .collection('art_walks')
          .limit(30)
          .get();

      for (final doc in artWalksQuery.docs) {
        final data = doc.data();
        final title = data['title'] as String? ?? '';
        final description = data['description'] as String? ?? '';
        final coverImageUrl = data['coverImageUrl'] as String?;
        final zipCode = data['zipCode'] as String? ?? '';

        // Check if query matches title, description, or zip code
        final titleLower = title.toLowerCase();
        final descriptionLower = description.toLowerCase();
        final zipCodeLower = zipCode.toLowerCase();

        bool matches = false;

        // Check title, description, and zip code
        if (titleLower.contains(lowerQuery) ||
            descriptionLower.contains(lowerQuery) ||
            zipCodeLower.contains(lowerQuery)) {
          matches = true;
        }

        if (matches) {
          results.add(
            HeaderSearchResult(
              id: doc.id,
              title: title.isNotEmpty ? title : 'Art Walk',
              subtitle: 'Art Walk${zipCode.isNotEmpty ? ' • $zipCode' : ''}',
              imageUrl: coverImageUrl,
              type: HeaderSearchResultType.artWalk,
              data: data,
            ),
          );
        }

        // Limit art walk results
        if (results
                .where((r) => r.type == HeaderSearchResultType.artWalk)
                .length >=
            2)
          break;
      }

      // Search artwork collection (if it exists)
      try {
        final artworkQuery = await FirebaseFirestore.instance
            .collection('artwork')
            .limit(20)
            .get();

        for (final doc in artworkQuery.docs) {
          final data = doc.data();
          final title = data['title'] as String? ?? '';
          final artistName = data['artistName'] as String? ?? '';
          final description = data['description'] as String? ?? '';
          final imageUrl = data['imageUrl'] as String?;
          final tags = data['tags'] as List<dynamic>? ?? [];

          // Check if query matches title, artist name, description, or tags
          final titleLower = title.toLowerCase();
          final artistNameLower = artistName.toLowerCase();
          final descriptionLower = description.toLowerCase();
          final tagsLower = tags
              .map((tag) => tag.toString().toLowerCase())
              .toList();

          bool matches = false;

          // Check title, artist name, and description
          if (titleLower.contains(lowerQuery) ||
              artistNameLower.contains(lowerQuery) ||
              descriptionLower.contains(lowerQuery)) {
            matches = true;
          }

          // Check tags
          if (!matches) {
            for (final tag in tagsLower) {
              if (tag.contains(lowerQuery)) {
                matches = true;
                break;
              }
            }
          }

          if (matches) {
            results.add(
              HeaderSearchResult(
                id: doc.id,
                title: title.isNotEmpty ? title : 'Untitled Artwork',
                subtitle: artistName.isNotEmpty ? 'by $artistName' : 'Artwork',
                imageUrl: imageUrl,
                type: HeaderSearchResultType.artwork,
                data: data,
              ),
            );
          }

          // Limit artwork results
          if (results
                  .where((r) => r.type == HeaderSearchResultType.artwork)
                  .length >=
              3)
            break;
        }
      } catch (e) {
        // Artwork collection might not exist, continue silently
      }
    } catch (e) {
      // Handle error silently
      debugPrint('Search error: $e');
    }

    debugPrint('Search for "$query" returned ${results.length} results');
    for (final result in results) {
      debugPrint('- ${result.title} (${result.type.name})');
    }

    return results;
  }

  void _showSearchOverlay() {
    _removeOverlay();

    if (_searchResults.isEmpty) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        top: offset.dy + size.height + 8,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  leading: _buildResultIcon(result),
                  title: Text(
                    result.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: result.subtitle.isNotEmpty
                      ? Text(result.subtitle)
                      : null,
                  onTap: () => _handleResultTap(result),
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildResultIcon(HeaderSearchResult result) {
    if (result.imageUrl != null && result.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          result.imageUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _getDefaultIcon(result.type),
        ),
      );
    }
    return _getDefaultIcon(result.type);
  }

  Widget _getDefaultIcon(HeaderSearchResultType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case HeaderSearchResultType.artist:
        iconData = Icons.person;
        color = Colors.blue;
        break;
      case HeaderSearchResultType.artwork:
        iconData = Icons.palette;
        color = Colors.purple;
        break;
      case HeaderSearchResultType.event:
        iconData = Icons.event;
        color = Colors.orange;
        break;
      case HeaderSearchResultType.artWalk:
        iconData = Icons.directions_walk;
        color = Colors.green;
        break;
      case HeaderSearchResultType.location:
        iconData = Icons.location_on;
        color = Colors.red;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(iconData, color: color),
    );
  }

  void _handleResultTap(HeaderSearchResult result) {
    _removeOverlay();
    _searchController.clear();

    switch (result.type) {
      case HeaderSearchResultType.artist:
        // Check if this is an artist profile or regular user
        final data = result.data;
        final isArtistProfile =
            data.containsKey('artistName') || data.containsKey('bio');

        if (isArtistProfile) {
          // Navigate to artist public profile
          Navigator.pushNamed(
            context,
            '/artist/public-profile',
            arguments: {'artistId': result.id},
          );
        } else {
          // Navigate to regular user profile

          Navigator.pushNamed(
            context,
            '/profile',
            arguments: {'userId': result.id},
          );
        }
        break;
      case HeaderSearchResultType.artwork:
        // Check if this is from captures or artwork collection
        final data = result.data;
        final isCapture =
            data.containsKey('capturedAt') || data.containsKey('userId');

        if (isCapture) {
          // Navigate to capture detail
          Navigator.pushNamed(
            context,
            '/capture/detail',
            arguments: {'captureId': result.id},
          );
        } else {
          // Navigate to artwork detail (if you have a separate artwork detail screen)
          Navigator.pushNamed(
            context,
            '/capture/detail', // Using capture detail for now
            arguments: {'captureId': result.id},
          );
        }
        break;
      case HeaderSearchResultType.event:
        // Navigate to event detail
        Navigator.pushNamed(
          context,
          '/events/detail',
          arguments: {'eventId': result.id},
        );
        break;
      case HeaderSearchResultType.artWalk:
        // Navigate to art walk detail
        Navigator.pushNamed(
          context,
          '/art-walk/detail',
          arguments: {'walkId': result.id},
        );
        break;
      case HeaderSearchResultType.location:
        // Handle location tap
        break;
    }
  }

  void _clearSearch() {
    setState(() {
      _searchResults.clear();
    });
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

/// Header search result model
class HeaderSearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final HeaderSearchResultType type;
  final Map<String, dynamic> data;

  HeaderSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.type,
    required this.data,
  });
}

/// Header search result types
enum HeaderSearchResultType { artist, artwork, event, artWalk, location }
