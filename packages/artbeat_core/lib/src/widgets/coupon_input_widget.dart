import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_tier.dart';
import '../services/subscription_service.dart';

/// Widget for entering and validating coupon codes during subscription purchase
class CouponInputWidget extends StatefulWidget {
  final SubscriptionTier selectedTier;
  final void Function(Map<String, dynamic>)? onCouponApplied;
  final void Function()? onCouponRemoved;

  const CouponInputWidget({
    super.key,
    required this.selectedTier,
    this.onCouponApplied,
    this.onCouponRemoved,
  });

  @override
  State<CouponInputWidget> createState() => _CouponInputWidgetState();
}

class _CouponInputWidgetState extends State<CouponInputWidget> {
  final TextEditingController _couponController = TextEditingController();
  final FocusNode _couponFocusNode = FocusNode();

  bool _isValidating = false;
  Map<String, dynamic>? _couponResult;
  String? _errorMessage;

  @override
  void dispose() {
    _couponController.dispose();
    _couponFocusNode.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon() async {
    final couponCode = _couponController.text.trim().toUpperCase();
    if (couponCode.isEmpty) return;

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final subscriptionService = context.read<SubscriptionService>();
      final result = await subscriptionService.validateCouponForSubscription(
        couponCode: couponCode,
        tier: widget.selectedTier,
      );

      setState(() {
        _isValidating = false;
        if (result['valid'] == true) {
          _couponResult = result;
          widget.onCouponApplied?.call(result);
        } else {
          _errorMessage = result['message'] as String?;
          _couponResult = null;
          widget.onCouponRemoved?.call();
        }
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _errorMessage = 'Failed to validate coupon: $e';
        _couponResult = null;
      });
      widget.onCouponRemoved?.call();
    }
  }

  void _removeCoupon() {
    setState(() {
      _couponController.clear();
      _couponResult = null;
      _errorMessage = null;
    });
    widget.onCouponRemoved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Have a coupon code?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Coupon input field
        if (_couponResult == null) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  focusNode: _couponFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    errorText: _errorMessage,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _validateCoupon(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isValidating ? null : _validateCoupon,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isValidating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
        ] else ...[
          // Coupon applied successfully
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _couponResult!['isFree'] == true
                      ? Icons.celebration
                      : Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_couponResult!['coupon'].title as String),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (_couponResult!['message'] as String),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_couponResult!['isFree'] != true) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Original: \$${_couponResult!['originalPrice'].toStringAsFixed(2)} → '
                          'Now: \$${_couponResult!['discountedPrice'].toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _removeCoupon,
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Error message
        if (_errorMessage != null && _couponResult == null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget to display pricing with coupon discount
class PricingDisplayWidget extends StatelessWidget {
  final SubscriptionTier tier;
  final Map<String, dynamic>? couponResult;

  const PricingDisplayWidget({
    super.key,
    required this.tier,
    this.couponResult,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final originalPrice = tier.monthlyPrice;
    final discountedPrice =
        couponResult?['discountedPrice'] as double? ?? originalPrice;
    final discountAmount = couponResult?['discountAmount'] as double? ?? 0.0;
    final isFree = couponResult?['isFree'] as bool? ?? false;

    return Column(
      children: [
        if (isFree) ...[
          // Free access display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.celebration,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'FREE ACCESS',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ] else if (discountAmount > 0) ...[
          // Discounted pricing
          Column(
            children: [
              Row(
                children: [
                  Text(
                    '\$${originalPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '-${((discountAmount / originalPrice) * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '\$${discountedPrice.toStringAsFixed(2)}/month',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ] else ...[
          // Regular pricing
          Text(
            '\$${originalPrice.toStringAsFixed(2)}/month',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
