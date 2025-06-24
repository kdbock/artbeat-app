import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:provider/provider.dart';

class AvatarWidget extends StatefulWidget {
  final String avatarUrl;
  final String? userId;
  final double radius;
  final VoidCallback? onTap;
  final String? displayName;

  const AvatarWidget({
    super.key,
    required this.avatarUrl,
    this.userId,
    this.radius = 24.0,
    this.onTap,
    this.displayName,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  String? _currentAvatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentAvatarUrl = widget.avatarUrl;

    // If avatar URL is empty and we have a userId, try to fetch current user data
    if ((widget.avatarUrl.isEmpty) && widget.userId != null) {
      _fetchUserAvatar();
    }
  }

  Future<void> _fetchUserAvatar() async {
    if (_isLoading || widget.userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final userModel = await userService.getUserById(widget.userId!);

      if (mounted &&
          userModel?.profileImageUrl != null &&
          userModel!.profileImageUrl!.isNotEmpty) {
        setState(() {
          _currentAvatarUrl = userModel.profileImageUrl;
        });
        debugPrint(
          '🔄 AvatarWidget: Updated avatar URL for user ${widget.userId}: "${userModel.profileImageUrl}"',
        );
      }
    } catch (e) {
      debugPrint('⚠️ AvatarWidget: Failed to fetch user avatar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎭 AvatarWidget build:');
    debugPrint('  - original avatarUrl: "${widget.avatarUrl}"');
    debugPrint('  - current avatarUrl: "${_currentAvatarUrl ?? 'null'}"');
    debugPrint('  - userId: "${widget.userId ?? 'null'}"');
    debugPrint('  - displayName: "${widget.displayName ?? 'User'}"');
    debugPrint(
      '  - will pass to UserAvatar: ${(_currentAvatarUrl?.isNotEmpty == true) ? _currentAvatarUrl : null}',
    );

    return UserAvatar(
      imageUrl: (_currentAvatarUrl?.isNotEmpty == true)
          ? _currentAvatarUrl
          : null,
      displayName: widget.displayName ?? 'User',
      radius: widget.radius,
      onTap: widget.onTap,
    );
  }
}
