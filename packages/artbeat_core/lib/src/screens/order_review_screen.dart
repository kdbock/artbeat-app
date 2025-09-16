import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';
import '../services/enhanced_payment_service_working.dart';

/// Types of transactions that can be reviewed
enum TransactionType {
  gift,
  subscription,
  advertisement,
  sponsorship,
  commission,
}

/// Data class for order details
class OrderDetails {
  final TransactionType type;
  final String title;
  final String description;
  final double originalAmount;
  final Map<String, dynamic> metadata;

  OrderDetails({
    required this.type,
    required this.title,
    required this.description,
    required this.originalAmount,
    required Map<String, dynamic> metadata,
  }) : metadata = Map.unmodifiable(metadata) {
    // Validate required fields
    _validateOrderDetails();
  }

  /// Validate order details based on transaction type
  void _validateOrderDetails() {
    if (title.isEmpty) {
      throw ArgumentError('Order title cannot be empty');
    }
    if (description.isEmpty) {
      throw ArgumentError('Order description cannot be empty');
    }
    if (originalAmount < 0) {
      throw ArgumentError('Original amount cannot be negative');
    }

    // Validate metadata based on transaction type
    _validateMetadataForTransactionType();
  }

  /// Validate metadata based on transaction type
  void _validateMetadataForTransactionType() {
    switch (type) {
      case TransactionType.gift:
        if (!metadata.containsKey('recipientId') ||
            metadata['recipientId'] == null) {
          throw ArgumentError('Gift transactions require a valid recipientId');
        }
        if (!metadata.containsKey('giftType') || metadata['giftType'] == null) {
          throw ArgumentError('Gift transactions require a valid giftType');
        }
        break;

      case TransactionType.subscription:
        if (!metadata.containsKey('tier') || metadata['tier'] == null) {
          throw ArgumentError('Subscription transactions require a valid tier');
        }
        if (!metadata.containsKey('billingCycle') ||
            metadata['billingCycle'] == null) {
          throw ArgumentError(
            'Subscription transactions require a valid billingCycle',
          );
        }
        break;

      case TransactionType.advertisement:
        if (!metadata.containsKey('adType') || metadata['adType'] == null) {
          throw ArgumentError(
            'Advertisement transactions require a valid adType',
          );
        }
        if (!metadata.containsKey('duration') || metadata['duration'] == null) {
          throw ArgumentError(
            'Advertisement transactions require a valid duration',
          );
        }
        break;

      case TransactionType.sponsorship:
        if (!metadata.containsKey('artistId') || metadata['artistId'] == null) {
          throw ArgumentError(
            'Sponsorship transactions require a valid artistId',
          );
        }
        if (!metadata.containsKey('sponsorshipType') ||
            metadata['sponsorshipType'] == null) {
          throw ArgumentError(
            'Sponsorship transactions require a valid sponsorshipType',
          );
        }
        if (!metadata.containsKey('duration') || metadata['duration'] == null) {
          throw ArgumentError(
            'Sponsorship transactions require a valid duration',
          );
        }
        if (!metadata.containsKey('benefits') || metadata['benefits'] == null) {
          throw ArgumentError(
            'Sponsorship transactions require valid benefits',
          );
        }
        break;

      case TransactionType.commission:
        if (!metadata.containsKey('artistId') || metadata['artistId'] == null) {
          throw ArgumentError(
            'Commission transactions require a valid artistId',
          );
        }
        if (!metadata.containsKey('commissionType') ||
            metadata['commissionType'] == null) {
          throw ArgumentError(
            'Commission transactions require a valid commissionType',
          );
        }
        if (!metadata.containsKey('description') ||
            metadata['description'] == null) {
          throw ArgumentError(
            'Commission transactions require a valid description',
          );
        }
        break;
    }
  }
}

/// Order review screen with coupon support
class OrderReviewScreen extends StatefulWidget {
  final OrderDetails orderDetails;
  final VoidCallback? onCancel;
  final void Function(Map<String, dynamic> result)? onPaymentComplete;

  const OrderReviewScreen({
    super.key,
    required this.orderDetails,
    this.onCancel,
    this.onPaymentComplete,
  });

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  final TextEditingController _couponController = TextEditingController();
  final CouponService _couponService = CouponService();
  final EnhancedPaymentService _paymentService = EnhancedPaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CouponModel? _appliedCoupon;
  bool _isValidatingCoupon = false;
  bool _isProcessingPayment = false;
  String? _couponError;
  double _finalAmount = 0.0;
  double _discountAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _finalAmount = widget.orderDetails.originalAmount;
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  /// Apply coupon code
  Future<void> _applyCoupon() async {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) return;

    setState(() {
      _isValidatingCoupon = true;
      _couponError = null;
    });

    try {
      final coupon = await _couponService.validateCoupon(couponCode);
      if (coupon == null) {
        setState(() {
          _couponError = 'Invalid or expired coupon code';
        });
        return;
      }

      // Check if coupon can be applied to this transaction type
      if (!_canApplyCouponToTransaction(coupon)) {
        setState(() {
          _couponError = 'This coupon cannot be applied to this transaction';
        });
        return;
      }

      final discountedPrice = coupon.calculateDiscountedPrice(
        widget.orderDetails.originalAmount,
      );
      final discountAmount =
          widget.orderDetails.originalAmount - discountedPrice;

      setState(() {
        _appliedCoupon = coupon;
        _finalAmount = discountedPrice;
        _discountAmount = discountAmount;
        _couponError = null;
      });

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coupon applied! You saved \$${discountAmount.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _couponError = e.toString();
      });
    } finally {
      setState(() {
        _isValidatingCoupon = false;
      });
    }
  }

  /// Remove applied coupon
  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _finalAmount = widget.orderDetails.originalAmount;
      _discountAmount = 0.0;
      _couponError = null;
    });
    _couponController.clear();
  }

  /// Check if coupon can be applied to this transaction type
  bool _canApplyCouponToTransaction(CouponModel coupon) {
    switch (widget.orderDetails.type) {
      case TransactionType.subscription:
        // Check if coupon allows this subscription tier
        final tierApiName = widget.orderDetails.metadata['tier'] as String?;
        if (tierApiName != null) {
          return coupon.canApplyToTier(tierApiName);
        }
        return true;
      case TransactionType.gift:
      case TransactionType.advertisement:
      case TransactionType.sponsorship:
      case TransactionType.commission:
        // For now, allow coupons on all transaction types
        // You can add specific logic here if needed
        return true;
    }
  }

  /// Process the payment
  Future<void> _processPayment() async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      Map<String, dynamic> result;

      switch (widget.orderDetails.type) {
        case TransactionType.gift:
          debugPrint(
            '🎁 Processing gift payment with final amount: \$${_finalAmount.toStringAsFixed(2)}',
          );
          debugPrint(
            '🎁 Original amount: \$${widget.orderDetails.originalAmount.toStringAsFixed(2)}',
          );

          // Handle 100% coupon case (free gift)
          if (_finalAmount == 0.0 && widget.orderDetails.originalAmount > 0.0) {
            debugPrint('🎁 Processing 100% coupon gift (free)');

            // Validate required metadata for free gift
            final recipientId = widget.orderDetails.metadata['recipientId'];
            final giftType = widget.orderDetails.metadata['giftType'];

            if (recipientId == null || giftType == null) {
              throw Exception(
                'Missing required metadata for free gift: recipientId or giftType is null',
              );
            }

            if (recipientId is! String || giftType is! String) {
              throw Exception(
                'Invalid metadata types for free gift: recipientId and giftType must be strings',
              );
            }

            // Create a free gift transaction without payment intent
            result = await _processFreeGift(
              recipientId: recipientId,
              giftType: giftType,
              originalAmount: widget.orderDetails.originalAmount,
              message: widget.orderDetails.metadata['message'] is String
                  ? widget.orderDetails.metadata['message'] as String
                  : null,
            );
          } else {
            // Validate required metadata for payment intent
            final recipientId = widget.orderDetails.metadata['recipientId'];
            final giftType = widget.orderDetails.metadata['giftType'];

            if (recipientId == null || giftType == null) {
              throw Exception(
                'Missing required metadata for gift payment: recipientId or giftType is null',
              );
            }

            if (recipientId is! String || giftType is! String) {
              throw Exception(
                'Invalid metadata types for gift payment: recipientId and giftType must be strings',
              );
            }

            // Create payment intent using enhanced service
            final paymentIntentData = await _createGiftPaymentIntent(
              recipientId: recipientId,
              amount: _finalAmount,
              giftType: giftType,
            );

            final clientSecret = paymentIntentData['clientSecret'];
            if (clientSecret == null || clientSecret is! String) {
              throw Exception('Invalid client secret from payment intent');
            }

            // Process payment with enhanced service
            final paymentResult = await _paymentService
                .processPaymentWithRiskAssessment(
                  paymentIntentClientSecret: clientSecret,
                  amount: _finalAmount,
                  currency: 'USD',
                  metadata: {
                    'type': 'gift',
                    'recipientId': widget.orderDetails.metadata['recipientId'],
                    'giftType': widget.orderDetails.metadata['giftType'],
                    'message': widget.orderDetails.metadata['message'],
                    'platform': 'ARTbeat',
                  },
                );

            result = {
              'status': paymentResult.success ? 'success' : 'failed',
              'paymentIntentId': paymentResult.paymentIntentId,
              'message':
                  paymentResult.error ?? 'Payment completed successfully',
            };
          }
          break;

        case TransactionType.subscription:
          // Validate required metadata for subscription
          final tier = widget.orderDetails.metadata['tier'];
          final billingCycle = widget.orderDetails.metadata['billingCycle'];

          if (tier == null || billingCycle == null) {
            throw Exception(
              'Missing required metadata for subscription: tier or billingCycle is null',
            );
          }

          if (tier is! String || billingCycle is! String) {
            throw Exception(
              'Invalid metadata types for subscription: tier and billingCycle must be strings',
            );
          }

          // Create payment intent for subscription
          final subscriptionIntentData = await _createSubscriptionPaymentIntent(
            tier: tier,
            amount: _finalAmount,
            billingCycle: billingCycle,
          );

          final clientSecret = subscriptionIntentData['clientSecret'];
          if (clientSecret == null || clientSecret is! String) {
            throw Exception(
              'Invalid client secret from subscription payment intent',
            );
          }

          // Process payment with enhanced service
          final paymentResult = await _paymentService
              .processPaymentWithRiskAssessment(
                paymentIntentClientSecret: clientSecret,
                amount: _finalAmount,
                currency: 'USD',
                metadata: {
                  'type': 'subscription',
                  'tier': widget.orderDetails.metadata['tier'],
                  'billingCycle': widget.orderDetails.metadata['billingCycle'],
                  'platform': 'ARTbeat',
                },
              );

          result = {
            'status': paymentResult.success ? 'success' : 'failed',
            'paymentIntentId': paymentResult.paymentIntentId,
            'message':
                paymentResult.error ??
                'Subscription payment completed successfully',
          };
          break;

        case TransactionType.advertisement:
          // Validate required metadata for advertisement
          final adType = widget.orderDetails.metadata['adType'];
          final duration = widget.orderDetails.metadata['duration'];

          if (adType == null || duration == null) {
            throw Exception(
              'Missing required metadata for advertisement: adType or duration is null',
            );
          }

          if (adType is! String || duration is! int) {
            throw Exception(
              'Invalid metadata types for advertisement: adType must be string, duration must be int',
            );
          }

          // Create payment intent for advertisement
          final adIntentData = await _createAdPaymentIntent(
            adType: adType,
            amount: _finalAmount,
            duration: duration,
            targetAudience: _getTargetAudienceMap(
              widget.orderDetails.metadata['targetAudience'],
            ),
            adContent:
                widget.orderDetails.metadata['adContent']
                    is Map<String, dynamic>
                ? widget.orderDetails.metadata['adContent']
                      as Map<String, dynamic>
                : null,
          );

          final clientSecret = adIntentData['clientSecret'];
          if (clientSecret == null || clientSecret is! String) {
            throw Exception(
              'Invalid client secret from advertisement payment intent',
            );
          }

          // Process payment with enhanced service
          final paymentResult = await _paymentService
              .processPaymentWithRiskAssessment(
                paymentIntentClientSecret: clientSecret,
                amount: _finalAmount,
                currency: 'USD',
                metadata: {
                  'type': 'advertisement',
                  'adType': widget.orderDetails.metadata['adType'],
                  'duration': widget.orderDetails.metadata['duration'],
                  'targetAudience':
                      widget.orderDetails.metadata['targetAudience'],
                  'platform': 'ARTbeat',
                },
              );

          result = {
            'status': paymentResult.success ? 'success' : 'failed',
            'paymentIntentId': paymentResult.paymentIntentId,
            'message':
                paymentResult.error ?? 'Ad payment completed successfully',
          };
          break;

        case TransactionType.sponsorship:
          // Validate required metadata for sponsorship
          final artistId = widget.orderDetails.metadata['artistId'];
          final sponsorshipType =
              widget.orderDetails.metadata['sponsorshipType'];
          final duration = widget.orderDetails.metadata['duration'];
          final benefits = widget.orderDetails.metadata['benefits'];

          if (artistId == null ||
              sponsorshipType == null ||
              duration == null ||
              benefits == null) {
            throw Exception(
              'Missing required metadata for sponsorship: artistId, sponsorshipType, duration, or benefits is null',
            );
          }

          if (artistId is! String ||
              sponsorshipType is! String ||
              duration is! int ||
              benefits is! List<String>) {
            throw Exception(
              'Invalid metadata types for sponsorship: artistId and sponsorshipType must be strings, duration must be int, benefits must be List<String>',
            );
          }

          // Create payment intent for sponsorship
          final sponsorshipIntentData = await _createSponsorshipPaymentIntent(
            artistId: artistId,
            sponsorshipType: sponsorshipType,
            amount: _finalAmount,
            duration: duration,
            benefits: benefits,
          );

          final clientSecret = sponsorshipIntentData['clientSecret'];
          if (clientSecret == null || clientSecret is! String) {
            throw Exception(
              'Invalid client secret from sponsorship payment intent',
            );
          }

          // Process payment with enhanced service
          final paymentResult = await _paymentService
              .processPaymentWithRiskAssessment(
                paymentIntentClientSecret: clientSecret,
                amount: _finalAmount,
                currency: 'USD',
                metadata: {
                  'type': 'sponsorship',
                  'artistId': widget.orderDetails.metadata['artistId'],
                  'sponsorshipType':
                      widget.orderDetails.metadata['sponsorshipType'],
                  'duration': widget.orderDetails.metadata['duration'],
                  'benefits': widget.orderDetails.metadata['benefits'],
                  'platform': 'ARTbeat',
                },
              );

          result = {
            'status': paymentResult.success ? 'success' : 'failed',
            'paymentIntentId': paymentResult.paymentIntentId,
            'message':
                paymentResult.error ??
                'Sponsorship payment completed successfully',
          };
          break;

        case TransactionType.commission:
          // Validate required metadata for commission
          final artistId = widget.orderDetails.metadata['artistId'];
          final commissionType = widget.orderDetails.metadata['commissionType'];
          final description = widget.orderDetails.metadata['description'];

          if (artistId == null ||
              commissionType == null ||
              description == null) {
            throw Exception(
              'Missing required metadata for commission: artistId, commissionType, or description is null',
            );
          }

          if (artistId is! String ||
              commissionType is! String ||
              description is! String) {
            throw Exception(
              'Invalid metadata types for commission: artistId, commissionType, and description must be strings',
            );
          }

          // Create payment intent for commission
          final commissionIntentData = await _createCommissionPaymentIntent(
            artistId: artistId,
            commissionType: commissionType,
            amount: _finalAmount,
            description: description,
            deadline: widget.orderDetails.metadata['deadline'] is DateTime
                ? widget.orderDetails.metadata['deadline'] as DateTime
                : null,
          );

          final clientSecret = commissionIntentData['clientSecret'];
          if (clientSecret == null || clientSecret is! String) {
            throw Exception(
              'Invalid client secret from commission payment intent',
            );
          }

          // Process payment with enhanced service
          final paymentResult = await _paymentService
              .processPaymentWithRiskAssessment(
                paymentIntentClientSecret: clientSecret,
                amount: _finalAmount,
                currency: 'USD',
                metadata: {
                  'type': 'commission',
                  'artistId': widget.orderDetails.metadata['artistId'],
                  'commissionType':
                      widget.orderDetails.metadata['commissionType'],
                  'description': widget.orderDetails.metadata['description'],
                  'deadline': widget.orderDetails.metadata['deadline'],
                  'platform': 'ARTbeat',
                },
              );

          result = {
            'status': paymentResult.success ? 'success' : 'failed',
            'paymentIntentId': paymentResult.paymentIntentId,
            'message':
                paymentResult.error ??
                'Commission payment completed successfully',
          };
          break;
      }

      // Redeem coupon if one was applied
      final appliedCoupon = _appliedCoupon;
      if (appliedCoupon != null) {
        await _couponService.redeemCoupon(appliedCoupon.id);
      }

      // Add coupon info to result
      result['couponApplied'] = _appliedCoupon?.toFirestore();
      result['originalAmount'] = widget.orderDetails.originalAmount;
      result['discountAmount'] = _discountAmount;
      result['finalAmount'] = _finalAmount;

      if (widget.onPaymentComplete != null) {
        final onPaymentComplete = widget.onPaymentComplete;
        if (onPaymentComplete != null) {
          onPaymentComplete(result);
        }
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] as String? ?? 'Payment successful!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Order'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getTransactionIcon(),
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Order Summary',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Theme.of(context).primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.orderDetails.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.orderDetails.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildOrderDetails(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Coupon Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_offer,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Promo Code',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context).primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_appliedCoupon == null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _couponController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter coupon code',
                                      border: const OutlineInputBorder(),
                                      errorText: _couponError,
                                    ),
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    inputFormatters: [UpperCaseTextFormatter()],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _isValidatingCoupon
                                      ? null
                                      : _applyCoupon,
                                  child: _isValidatingCoupon
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Apply'),
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.green),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _appliedCoupon!.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        Text(
                                          _appliedCoupon!.title,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _removeCoupon,
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price Breakdown Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price Breakdown',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Text(
                                '\$${widget.orderDetails.originalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          if (_appliedCoupon != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Discount (${_appliedCoupon!.code})',
                                  style: const TextStyle(color: Colors.green),
                                ),
                                Text(
                                  '-\$${_discountAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ],
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context).primaryColor,
                                    ),
                              ),
                              Text(
                                '\$${_finalAmount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Payment Button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessingPayment ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessingPayment
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Processing...'),
                          ],
                        )
                      : Text(
                          _finalAmount == 0.0
                              ? 'Complete Order (Free)'
                              : 'Pay \$${_finalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get icon for transaction type
  IconData _getTransactionIcon() {
    switch (widget.orderDetails.type) {
      case TransactionType.gift:
        return Icons.card_giftcard;
      case TransactionType.subscription:
        return Icons.star;
      case TransactionType.advertisement:
        return Icons.campaign;
      case TransactionType.sponsorship:
        return Icons.handshake;
      case TransactionType.commission:
        return Icons.brush;
    }
  }

  /// Build order-specific details
  Widget _buildOrderDetails() {
    switch (widget.orderDetails.type) {
      case TransactionType.gift:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Type',
              widget.orderDetails.metadata['giftType'] as String? ?? 'Unknown',
            ),
            if (widget.orderDetails.metadata['message'] != null)
              _buildDetailRow(
                'Message',
                widget.orderDetails.metadata['message'] as String? ?? '',
              ),
          ],
        );

      case TransactionType.subscription:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Tier',
              widget.orderDetails.metadata['tier'] as String? ?? 'Unknown',
            ),
            _buildDetailRow(
              'Billing',
              widget.orderDetails.metadata['billingCycle'] as String? ??
                  'Unknown',
            ),
          ],
        );

      case TransactionType.advertisement:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Type',
              widget.orderDetails.metadata['adType'] as String? ?? 'Unknown',
            ),
            _buildDetailRow(
              'Duration',
              '${widget.orderDetails.metadata['duration'] ?? 'Unknown'} days',
            ),
          ],
        );

      case TransactionType.sponsorship:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Type',
              widget.orderDetails.metadata['sponsorshipType'] as String? ??
                  'Unknown',
            ),
            _buildDetailRow(
              'Duration',
              '${widget.orderDetails.metadata['duration'] ?? 'Unknown'} days',
            ),
          ],
        );

      case TransactionType.commission:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Type',
              widget.orderDetails.metadata['commissionType'] as String? ??
                  'Unknown',
            ),
            _buildDetailRow(
              'Description',
              widget.orderDetails.metadata['description'] as String? ??
                  'No description',
            ),
          ],
        );
    }
  }

  /// Build a detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to safely convert targetAudience to Map<String, dynamic>?
  Map<String, dynamic>? _getTargetAudienceMap(dynamic targetAudience) {
    if (targetAudience == null) return null;

    if (targetAudience is Map<String, dynamic>) {
      return targetAudience;
    }

    if (targetAudience is String && targetAudience.isNotEmpty) {
      return {'audience': targetAudience};
    }

    return null;
  }

  /// Process free gift (100% coupon case)
  Future<Map<String, dynamic>> _processFreeGift({
    required String recipientId,
    required String giftType,
    required double originalAmount,
    String? message,
  }) async {
    try {
      debugPrint('🎁 Processing free gift transaction');

      // For free gifts, record directly in Firestore instead of using payment service
      final giftData = {
        'recipientId': recipientId,
        'senderId': _auth.currentUser?.uid,
        'giftType': giftType,
        'originalAmount': originalAmount,
        'finalAmount': 0.0,
        'message': message,
        'type': 'free_gift',
        'platform': 'ARTbeat',
        'couponApplied': true,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {
          'gift_type': giftType,
          'recipient_id': recipientId,
          'original_amount': originalAmount,
          'coupon_discount': originalAmount,
          'platform': 'ARTbeat',
        },
      };

      // Record the gift in Firestore
      await FirebaseFirestore.instance.collection('gifts').add(giftData);

      debugPrint('🎁 Free gift recorded successfully in Firestore');

      return {
        'status': 'success',
        'paymentIntentId': 'free_gift_${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Free gift sent successfully! (100% coupon applied)',
      };
    } catch (e) {
      debugPrint('❌ Error processing free gift: ${e.toString()}');
      return {
        'status': 'failed',
        'paymentIntentId': null,
        'message': 'Failed to process free gift: ${e.toString()}',
      };
    }
  }

  /// Create payment intent for gift using enhanced service
  Future<Map<String, dynamic>> _createGiftPaymentIntent({
    required String recipientId,
    required double amount,
    required String giftType,
  }) async {
    final body = {
      'amount': (amount * 100).toInt(), // Convert to cents
      'currency': 'usd',
      'recipientId': recipientId,
      'giftType': giftType,
      'type': 'gift',
      'platform': 'ARTbeat',
      'deviceFingerprint': await _paymentService.getDeviceFingerprint(),
      'metadata': {
        'gift_type': giftType,
        'recipient_id': recipientId,
        'platform': 'ARTbeat',
      },
    };

    // Use the enhanced payment service's authenticated request method
    final response = await _paymentService.makeAuthenticatedRequest(
      functionKey: 'processGiftPayment',
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create gift payment intent: ${response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Create payment intent for subscription using enhanced service
  Future<Map<String, dynamic>> _createSubscriptionPaymentIntent({
    required String tier,
    required double amount,
    required String billingCycle,
  }) async {
    final body = {
      'amount': (amount * 100).toInt(), // Convert to cents
      'currency': 'usd',
      'tier': tier,
      'billingCycle': billingCycle,
      'type': 'subscription',
      'platform': 'ARTbeat',
      'deviceFingerprint': await _paymentService.getDeviceFingerprint(),
      'metadata': {
        'tier': tier,
        'billing_cycle': billingCycle,
        'platform': 'ARTbeat',
      },
    };

    // Use the enhanced payment service's authenticated request method
    final response = await _paymentService.makeAuthenticatedRequest(
      functionKey: 'processSubscriptionPayment',
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create subscription payment intent: ${response.body}',
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Create payment intent for advertisement using enhanced service
  Future<Map<String, dynamic>> _createAdPaymentIntent({
    required String adType,
    required double amount,
    required int duration,
    Map<String, dynamic>? targetAudience,
    Map<String, dynamic>? adContent,
  }) async {
    final body = {
      'amount': (amount * 100).toInt(), // Convert to cents
      'currency': 'usd',
      'adType': adType,
      'duration': duration,
      'type': 'advertisement',
      'platform': 'ARTbeat',
      'deviceFingerprint': await _paymentService.getDeviceFingerprint(),
      'metadata': {
        'ad_type': adType,
        'duration': duration,
        'target_audience': targetAudience,
        'ad_content': adContent,
        'platform': 'ARTbeat',
      },
    };

    // Use the enhanced payment service's authenticated request method
    final response = await _paymentService.makeAuthenticatedRequest(
      functionKey: 'processAdPayment',
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create ad payment intent: ${response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Create payment intent for sponsorship using enhanced service
  Future<Map<String, dynamic>> _createSponsorshipPaymentIntent({
    required String artistId,
    required String sponsorshipType,
    required double amount,
    required int duration,
    required List<String> benefits,
  }) async {
    final body = {
      'amount': (amount * 100).toInt(), // Convert to cents
      'currency': 'usd',
      'artistId': artistId,
      'sponsorshipType': sponsorshipType,
      'duration': duration,
      'benefits': benefits,
      'type': 'sponsorship',
      'platform': 'ARTbeat',
      'deviceFingerprint': await _paymentService.getDeviceFingerprint(),
      'metadata': {
        'artist_id': artistId,
        'sponsorship_type': sponsorshipType,
        'duration': duration,
        'benefits': benefits,
        'platform': 'ARTbeat',
      },
    };

    // Use the enhanced payment service's authenticated request method
    final response = await _paymentService.makeAuthenticatedRequest(
      functionKey: 'processSponsorshipPayment',
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create sponsorship payment intent: ${response.body}',
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Create payment intent for commission using enhanced service
  Future<Map<String, dynamic>> _createCommissionPaymentIntent({
    required String artistId,
    required String commissionType,
    required double amount,
    required String description,
    DateTime? deadline,
  }) async {
    final body = {
      'amount': (amount * 100).toInt(), // Convert to cents
      'currency': 'usd',
      'artistId': artistId,
      'commissionType': commissionType,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'type': 'commission',
      'platform': 'ARTbeat',
      'deviceFingerprint': await _paymentService.getDeviceFingerprint(),
      'metadata': {
        'artist_id': artistId,
        'commission_type': commissionType,
        'description': description,
        'deadline': deadline?.toIso8601String(),
        'platform': 'ARTbeat',
      },
    };

    // Use the enhanced payment service's authenticated request method
    final response = await _paymentService.makeAuthenticatedRequest(
      functionKey: 'processCommissionPayment',
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create commission payment intent: ${response.body}',
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }
}

/// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
