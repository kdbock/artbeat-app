import 'package:flutter/material.dart';
import '../models/engagement_model.dart';
import '../services/universal_engagement_service.dart';
import '../theme/artbeat_colors.dart';

/// Universal engagement bar for all ARTbeat content types
/// Displays Appreciate, Connect, Discuss, Amplify, and Gift actions
class UniversalEngagementBar extends StatefulWidget {
  final String contentId;
  final String contentType;
  final EngagementStats initialStats;
  final VoidCallback? onDiscuss;
  final VoidCallback? onAmplify;
  final VoidCallback? onGift;
  final bool showConnect;
  final bool showGift;
  final bool isCompact;
  final String? targetUserId; // For connect action on profiles

  const UniversalEngagementBar({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.initialStats,
    this.onDiscuss,
    this.onAmplify,
    this.onGift,
    this.showConnect = false,
    this.showGift = false,
    this.isCompact = false,
    this.targetUserId,
  });

  @override
  State<UniversalEngagementBar> createState() => _UniversalEngagementBarState();
}

class _UniversalEngagementBarState extends State<UniversalEngagementBar> {
  late EngagementStats _stats;
  final UniversalEngagementService _engagementService =
      UniversalEngagementService();

  bool _hasAppreciated = false;
  bool _hasConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _stats = widget.initialStats;
    _loadEngagementStates();
  }

  Future<void> _loadEngagementStates() async {
    try {
      final appreciated = await _engagementService.hasUserEngaged(
        contentId: widget.contentId,
        engagementType: EngagementType.appreciate,
      );

      bool connected = false;
      if (widget.showConnect && widget.targetUserId != null) {
        connected = await _engagementService.hasUserEngaged(
          contentId: widget.targetUserId!,
          engagementType: EngagementType.connect,
        );
      }

      if (mounted) {
        setState(() {
          _hasAppreciated = appreciated;
          _hasConnected = connected;
        });
      }
    } catch (e) {
      debugPrint('Error loading engagement states: $e');
    }
  }

  Future<void> _handleEngagement(EngagementType type) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String targetContentId = widget.contentId;
      String targetContentType = widget.contentType;

      // For connect action on profiles, use the target user ID
      if (type == EngagementType.connect && widget.targetUserId != null) {
        targetContentId = widget.targetUserId!;
        targetContentType = 'profile';
      }

      final newState = await _engagementService.toggleEngagement(
        contentId: targetContentId,
        contentType: targetContentType,
        engagementType: type,
      );

      // Update local state
      setState(() {
        switch (type) {
          case EngagementType.appreciate:
            _hasAppreciated = newState;
            _stats = _stats.copyWith(
              appreciateCount: newState
                  ? _stats.appreciateCount + 1
                  : _stats.appreciateCount - 1,
            );
            break;
          case EngagementType.connect:
            _hasConnected = newState;
            _stats = _stats.copyWith(
              connectCount: newState
                  ? _stats.connectCount + 1
                  : _stats.connectCount - 1,
            );
            break;
          case EngagementType.discuss:
            // Discuss count is handled by the discussion system
            break;
          case EngagementType.amplify:
            _stats = _stats.copyWith(
              amplifyCount: newState
                  ? _stats.amplifyCount + 1
                  : _stats.amplifyCount - 1,
            );
            break;
          case EngagementType.gift:
            // Gift engagement is handled separately through payment flow
            break;
        }
      });

      // Show feedback
      if (mounted) {
        final message = newState
            ? '${type.displayName} added!'
            : '${type.displayName} removed';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling engagement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    if (widget.isCompact) {
      return _buildCompactBar();
    }
    return _buildFullBar();
  }

  Widget _buildFullBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Appreciate
          Expanded(
            child: _buildEngagementButton(
              type: EngagementType.appreciate,
              count: _stats.appreciateCount,
              isActive: _hasAppreciated,
              onTap: () => _handleEngagement(EngagementType.appreciate),
            ),
          ),
          const SizedBox(width: 8),

          // Connect (only show if enabled)
          if (widget.showConnect) ...[
            Expanded(
              child: _buildEngagementButton(
                type: EngagementType.connect,
                count: _stats.connectCount,
                isActive: _hasConnected,
                onTap: () => _handleEngagement(EngagementType.connect),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Discuss
          Expanded(
            child: _buildEngagementButton(
              type: EngagementType.discuss,
              count: _stats.discussCount,
              isActive: false,
              onTap:
                  widget.onDiscuss ??
                  () => _handleEngagement(EngagementType.discuss),
            ),
          ),
          const SizedBox(width: 8),

          // Amplify
          Expanded(
            child: _buildEngagementButton(
              type: EngagementType.amplify,
              count: _stats.amplifyCount,
              isActive: false,
              onTap:
                  widget.onAmplify ??
                  () => _handleEngagement(EngagementType.amplify),
            ),
          ),

          // Gift (only show if enabled)
          if (widget.showGift) ...[
            const SizedBox(width: 8),
            Expanded(child: _buildGiftButton()),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactButton(
          type: EngagementType.appreciate,
          count: _stats.appreciateCount,
          isActive: _hasAppreciated,
          onTap: () => _handleEngagement(EngagementType.appreciate),
        ),
        const SizedBox(width: 16),
        _buildCompactButton(
          type: EngagementType.discuss,
          count: _stats.discussCount,
          isActive: false,
          onTap:
              widget.onDiscuss ??
              () => _handleEngagement(EngagementType.discuss),
        ),
        const SizedBox(width: 16),
        _buildCompactButton(
          type: EngagementType.amplify,
          count: _stats.amplifyCount,
          isActive: false,
          onTap:
              widget.onAmplify ??
              () => _handleEngagement(EngagementType.amplify),
        ),
      ],
    );
  }

  Widget _buildEngagementButton({
    required EngagementType type,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = _getEngagementColor(type);

    return Tooltip(
      message: _getTooltipMessage(type, count, isActive),
      child: GestureDetector(
        onTap: _isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? color.withAlpha(51) : color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? color : color.withAlpha(77),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getEngagementIcon(type),
                size: 18,
                color: isActive ? color : color.withAlpha(179),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  count > 0 ? count.toString() : type.displayName,
                  style: TextStyle(
                    color: isActive ? color : color.withAlpha(179),
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactButton({
    required EngagementType type,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = _getEngagementColor(type);

    return Tooltip(
      message: _getTooltipMessage(type, count, isActive),
      child: GestureDetector(
        onTap: _isLoading ? null : onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getEngagementIcon(type),
              size: 16,
              color: isActive ? color : color.withAlpha(179),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  color: isActive ? color : color.withAlpha(179),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getEngagementColor(EngagementType type) {
    switch (type) {
      case EngagementType.appreciate:
        return ArtbeatColors.accentYellow;
      case EngagementType.connect:
        return ArtbeatColors.primaryPurple;
      case EngagementType.discuss:
        return ArtbeatColors.primaryGreen;
      case EngagementType.amplify:
        return ArtbeatColors.accentOrange;
      case EngagementType.gift:
        return ArtbeatColors.accentGold;
    }
  }

  IconData _getEngagementIcon(EngagementType type) {
    switch (type) {
      case EngagementType.appreciate:
        return Icons.palette_outlined;
      case EngagementType.connect:
        return Icons.link;
      case EngagementType.discuss:
        return Icons.chat_bubble_outline;
      case EngagementType.amplify:
        return Icons.campaign_outlined;
      case EngagementType.gift:
        return Icons.card_giftcard;
    }
  }

  String _getTooltipMessage(EngagementType type, int count, bool isActive) {
    switch (type) {
      case EngagementType.appreciate:
        if (isActive) {
          return 'You appreciated this • $count total';
        } else {
          return count > 0 
              ? 'Appreciate this artist • $count appreciations'
              : 'Appreciate this artist';
        }
      case EngagementType.connect:
        if (isActive) {
          return 'You are connected • $count connections';
        } else {
          return count > 0 
              ? 'Connect with this artist • $count connections'
              : 'Connect with this artist';
        }
      case EngagementType.discuss:
        return count > 0 
            ? 'Join the discussion • $count comments'
            : 'Start a discussion';
      case EngagementType.amplify:
        return count > 0 
            ? 'Amplify this artist • $count amplifications'
            : 'Amplify this artist';
      case EngagementType.gift:
        return count > 0 
            ? 'Send a gift • $count gifts received'
            : 'Send a gift to this artist';
    }
  }

  Widget _buildGiftButton() {
    const color = ArtbeatColors.accentGold;
    final hasGifts = _stats.giftCount > 0;

    return Tooltip(
      message: _getTooltipMessage(EngagementType.gift, _stats.giftCount, false),
      child: GestureDetector(
        onTap: _isLoading ? null : (widget.onGift ?? () => _handleGiftAction()),
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: hasGifts ? color.withAlpha(51) : color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasGifts ? color : color.withAlpha(77),
            width: hasGifts ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 18,
              color: hasGifts ? color : color.withAlpha(179),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _stats.giftCount > 0 ? _stats.giftCount.toString() : 'Gift',
                    style: TextStyle(
                      color: hasGifts ? color : color.withAlpha(179),
                      fontSize: 12,
                      fontWeight: hasGifts ? FontWeight.w600 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_stats.totalGiftValue > 0)
                    Text(
                      '\$${_stats.totalGiftValue.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: hasGifts ? color : color.withAlpha(179),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _handleGiftAction() {
    // This will open the gift modal/screen
    // Implementation depends on the specific gift flow
    if (widget.onGift != null) {
      widget.onGift!();
    }
  }
}
