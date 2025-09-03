import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/engagement_model.dart';
import '../services/engagement_config_service.dart';
import '../services/content_engagement_service.dart';

/// Content-specific engagement bar for ARTbeat content types
/// Replaces the universal engagement bar with content-specific engagement options
class ContentEngagementBar extends StatefulWidget {
  final String contentId;
  final String contentType;
  final EngagementStats initialStats;
  final bool isCompact;
  final Map<EngagementType, VoidCallback?>? customHandlers;
  final bool showSecondaryActions;
  final EdgeInsets? padding;

  const ContentEngagementBar({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.initialStats,
    this.isCompact = false,
    this.customHandlers,
    this.showSecondaryActions = false,
    this.padding,
  });

  @override
  State<ContentEngagementBar> createState() => _ContentEngagementBarState();
}

class _ContentEngagementBarState extends State<ContentEngagementBar> {
  late EngagementStats _stats;
  final Map<EngagementType, bool> _userEngagements = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _stats = widget.initialStats;
    _loadUserEngagements();
  }

  Future<void> _loadUserEngagements() async {
    final service = context.read<ContentEngagementService>();
    final primaryTypes = EngagementConfigService.getPrimaryEngagementTypes(
      widget.contentType,
    );

    for (final type in primaryTypes) {
      final hasEngaged = await service.hasUserEngaged(
        contentId: widget.contentId,
        engagementType: type,
      );
      if (mounted) {
        setState(() {
          _userEngagements[type] = hasEngaged;
        });
      }
    }
  }

  Future<void> _handleEngagement(EngagementType type) async {
    if (_isLoading) return;

    // Check for custom handler first
    final customHandler = widget.customHandlers?[type];
    if (customHandler != null) {
      customHandler();
      return;
    }

    // Handle special engagement types
    if (EngagementConfigService.requiresSpecialHandling(type)) {
      await _handleSpecialEngagement(type);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = context.read<ContentEngagementService>();
      final newEngagementState = await service.toggleEngagement(
        contentId: widget.contentId,
        contentType: widget.contentType,
        engagementType: type,
      );

      if (mounted) {
        setState(() {
          _userEngagements[type] = newEngagementState;
          _stats = _updateStatsForEngagement(type, newEngagementState);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _handleSpecialEngagement(EngagementType type) async {
    switch (type) {
      case EngagementType.gift:
        await _showGiftDialog();
        break;
      case EngagementType.sponsor:
        await _showSponsorDialog();
        break;
      case EngagementType.commission:
        await _showCommissionDialog();
        break;
      case EngagementType.message:
        await _showMessageDialog();
        break;
      case EngagementType.review:
        await _showReviewDialog();
        break;
      default:
        // Handle normally
        await _handleEngagement(type);
    }
  }

  EngagementStats _updateStatsForEngagement(
    EngagementType type,
    bool isEngaged,
  ) {
    final increment = isEngaged ? 1 : -1;

    switch (type) {
      case EngagementType.like:
        return _stats.copyWith(
          likeCount: (_stats.likeCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.comment:
        return _stats.copyWith(
          commentCount: (_stats.commentCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.reply:
        return _stats.copyWith(
          replyCount: (_stats.replyCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.share:
        return _stats.copyWith(
          shareCount: (_stats.shareCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.rate:
        return _stats.copyWith(
          rateCount: (_stats.rateCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.review:
        return _stats.copyWith(
          reviewCount: (_stats.reviewCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.follow:
        return _stats.copyWith(
          followCount: (_stats.followCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.gift:
        return _stats.copyWith(
          giftCount: (_stats.giftCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.sponsor:
        return _stats.copyWith(
          sponsorCount: (_stats.sponsorCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.message:
        return _stats.copyWith(
          messageCount: (_stats.messageCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      case EngagementType.commission:
        return _stats.copyWith(
          commissionCount: (_stats.commissionCount + increment)
              .clamp(0, double.infinity)
              .toInt(),
        );
      default:
        return _stats;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryTypes = EngagementConfigService.getPrimaryEngagementTypes(
      widget.contentType,
    );
    final secondaryTypes = widget.showSecondaryActions
        ? EngagementConfigService.getSecondaryEngagementTypes(
            widget.contentType,
          )
        : <EngagementType>[];

    return Container(
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Primary engagement actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: primaryTypes
                .map((type) => _buildEngagementButton(type))
                .toList(),
          ),

          // Secondary engagement actions (if enabled)
          if (secondaryTypes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: secondaryTypes
                  .map(
                    (type) => _buildEngagementButton(type, isSecondary: true),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEngagementButton(
    EngagementType type, {
    bool isSecondary = false,
  }) {
    final isEngaged = _userEngagements[type] ?? false;
    final count = _stats.getCount(type);
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _handleEngagement(type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 8 : 12,
          vertical: widget.isCompact ? 4 : 8,
        ),
        child: widget.isCompact
            ? _buildCompactButton(type, isEngaged, count, theme)
            : _buildFullButton(type, isEngaged, count, theme, isSecondary),
      ),
    );
  }

  Widget _buildCompactButton(
    EngagementType type,
    bool isEngaged,
    int count,
    ThemeData theme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getIconData(type),
          size: 16,
          color: isEngaged
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text(
            _formatCount(count),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isEngaged
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFullButton(
    EngagementType type,
    bool isEngaged,
    int count,
    ThemeData theme,
    bool isSecondary,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getIconData(type),
          size: isSecondary ? 20 : 24,
          color: isEngaged
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 4),
        Text(
          count > 0 ? _formatCount(count) : type.displayName,
          style:
              (isSecondary
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                    color: isEngaged
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
        ),
      ],
    );
  }

  IconData _getIconData(EngagementType type) {
    switch (type) {
      case EngagementType.like:
        return Icons.favorite; // heart icon
      case EngagementType.comment:
        return Icons.chat_bubble_outline; // chat bubble
      case EngagementType.reply:
        return Icons.reply; // reply arrow
      case EngagementType.share:
        return Icons.share; // share icon
      case EngagementType.seen:
        return Icons.visibility; // eye icon
      case EngagementType.rate:
        return Icons.star_border; // star for rating
      case EngagementType.review:
        return Icons.rate_review; // review icon
      case EngagementType.follow:
        return Icons.person_add; // follow icon
      case EngagementType.gift:
        return Icons.card_giftcard; // gift icon
      case EngagementType.sponsor:
        return Icons.volunteer_activism; // sponsor icon
      case EngagementType.message:
        return Icons.message; // message icon
      case EngagementType.commission:
        return Icons.palette; // commission icon (more art-related)
    }
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  // Placeholder methods for special engagement dialogs
  Future<void> _showGiftDialog() async {
    // TODO: Implement gift dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Gift feature coming soon!')));
  }

  Future<void> _showSponsorDialog() async {
    // TODO: Implement sponsor dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sponsor feature coming soon!')),
    );
  }

  Future<void> _showCommissionDialog() async {
    // TODO: Implement commission dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commission feature coming soon!')),
    );
  }

  Future<void> _showMessageDialog() async {
    // TODO: Implement message dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message feature coming soon!')),
    );
  }

  Future<void> _showReviewDialog() async {
    // TODO: Implement review dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review feature coming soon!')),
    );
  }
}
