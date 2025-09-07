import 'package:flutter/material.dart';
import 'package:artbeat_core/src/models/subscription_plan.dart';
import 'package:artbeat_core/src/widgets/artbeat_button.dart';

/// Enhanced subscription card with advanced UX features
class EnhancedSubscriptionCard extends StatefulWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback? onTap;
  final VoidCallback? onCompareTap;
  final bool showComparison;
  final Animation<double>? animation;

  const EnhancedSubscriptionCard({
    super.key,
    required this.plan,
    this.isSelected = false,
    this.isRecommended = false,
    this.onTap,
    this.onCompareTap,
    this.showComparison = false,
    this.animation,
  });

  @override
  State<EnhancedSubscriptionCard> createState() =>
      _EnhancedSubscriptionCardState();
}

class _EnhancedSubscriptionCardState extends State<EnhancedSubscriptionCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      _scaleController.forward().then((_) {
        _scaleController.reverse();
        widget.onTap!();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _glowAnimation,
        widget.animation,
      ]),
      builder: (context, child) {
        final scale = _scaleAnimation.value;
        final glowOpacity = _glowAnimation.value * 0.3;

        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: widget.isSelected
                  ? LinearGradient(
                      colors: [
                        theme.primaryColor.withValues(alpha: 0.1),
                        theme.primaryColor.withValues(alpha: 0.05),
                      ],
                    )
                  : null,
              border: Border.all(
                color: widget.isSelected
                    ? theme.primaryColor
                    : theme.dividerColor.withValues(alpha: 0.3),
                width: widget.isSelected ? 2 : 1,
              ),
              boxShadow: widget.isRecommended
                  ? [
                      BoxShadow(
                        color: theme.primaryColor.withValues(
                          alpha: glowOpacity,
                        ),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with badge and title
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.plan.badgeText != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.isRecommended
                                          ? theme.primaryColor
                                          : theme.secondaryHeaderColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      widget.plan.badgeText!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.plan.name,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: widget.isSelected
                                            ? theme.primaryColor
                                            : theme
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.color,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.plan.priceString,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: widget.isSelected
                                      ? theme.primaryColor
                                      : theme.textTheme.headlineMedium?.color,
                                ),
                              ),
                              if (widget.plan.annualPriceString != null)
                                Text(
                                  widget.plan.annualPriceString!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.6),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              if (widget.plan.savingsString != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.plan.savingsString!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Description
                      Text(
                        widget.plan.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Key features
                      ...widget.plan.highlights.map(
                        (highlight) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 20,
                                color: widget.isSelected
                                    ? theme.primaryColor
                                    : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  highlight,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ArtbeatButton(
                              onPressed: widget.isSelected ? null : _handleTap,
                              variant: widget.isRecommended
                                  ? ButtonVariant.primary
                                  : ButtonVariant.secondary,
                              child: Text(
                                widget.isSelected
                                    ? 'Current Plan'
                                    : 'Select Plan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (widget.showComparison &&
                              widget.onCompareTap != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: IconButton(
                                onPressed: widget.onCompareTap,
                                icon: Icon(
                                  Icons.compare_arrows,
                                  color: theme.iconTheme.color?.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                tooltip: 'Compare plans',
                              ),
                            ),
                        ],
                      ),

                      // Additional details
                      if (widget.plan.hasUnlimitedArtworks ||
                          widget.plan.hasUnlimitedStorage ||
                          widget.plan.hasUnlimitedAiCredits)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Unlimited Features',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
