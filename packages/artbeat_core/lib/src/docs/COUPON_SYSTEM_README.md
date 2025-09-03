# App-Wide Coupon System

This system allows you to create promotional codes that provide users with free or discounted access to all app services while still tracking purchases for analytics purposes.

## Features

- **Full Access Coupons**: Grant users complete access to all features for free
- **Percentage Discounts**: Apply percentage-based discounts to subscriptions
- **Fixed Amount Discounts**: Apply fixed dollar amount discounts
- **Usage Limits**: Control how many times each coupon can be used
- **Expiration Dates**: Set time limits on coupon validity
- **Analytics Tracking**: Track coupon usage and revenue impact
- **Admin Management**: Complete UI for creating and managing coupons

## Key Benefits

1. **Zero Revenue Impact**: Free access coupons don't generate Stripe charges
2. **Analytics Preservation**: All "purchases" are still tracked in your database
3. **Flexible Promotion**: Support for beta testing, referrals, limited-time offers
4. **Usage Control**: Prevent abuse with configurable limits and expiration
5. **Easy Integration**: Drop-in widgets for subscription flows

## Quick Start

### 1. Create a Full Access Coupon

```dart
final couponService = CouponService();

final couponId = await couponService.createFullAccessCoupon(
  title: 'Beta Tester Access',
  description: 'Full access for beta testers',
  maxUses: 1000,
  expiresAt: DateTime.now().add(Duration(days: 90)),
);
```

### 2. Integrate into Subscription Flow

```dart
// In your subscription purchase screen
CouponInputWidget(
  selectedTier: selectedTier,
  onCouponApplied: (result) {
    // Handle successful coupon application
    final isFree = result['isFree'];
    final discountAmount = result['discountAmount'];
  },
  onCouponRemoved: () {
    // Handle coupon removal
  },
)
```

### 3. Process Subscription with Coupon

```dart
final subscriptionService = SubscriptionService();
final result = await subscriptionService.createSubscriptionWithCoupon(
  tier: selectedTier,
  couponCode: couponCode, // Optional
  paymentMethodId: paymentMethodId, // Optional for free access
);
```

## Coupon Types

### Full Access (Free)

- Grants complete access to all features
- No payment required
- Perfect for beta testing, referrals, or promotions

### Percentage Discount

- Reduces subscription price by a percentage
- Example: 50% off first year
- Configurable discount amount

### Fixed Discount

- Reduces subscription price by a fixed amount
- Example: $10 off
- Useful for specific promotions

### Free Trial

- Provides temporary access
- Can be extended or converted to paid

## Database Schema

### Coupons Collection

```json
{
  "id": "coupon_id",
  "code": "BETA2025",
  "title": "Beta Access",
  "description": "Full access for beta testers",
  "type": "full_access",
  "status": "active",
  "maxUses": 1000,
  "currentUses": 45,
  "expiresAt": "2025-12-31T23:59:59Z",
  "createdAt": "2025-01-01T00:00:00Z",
  "createdBy": "admin_user_id"
}
```

### Subscriptions Collection (with coupon tracking)

```json
{
  "userId": "user_id",
  "tier": "creator",
  "couponCode": "BETA2025",
  "couponId": "coupon_id",
  "originalPrice": 12.99,
  "discountedPrice": 0.0,
  "revenue": 0.0,
  "isFree": true,
  "createdAt": "2025-01-01T00:00:00Z"
}
```

## Admin Management

Use the `CouponManagementScreen` to:

- Create new coupons
- View coupon usage statistics
- Activate/deactivate coupons
- Set expiration dates and usage limits

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CouponManagementScreen(),
  ),
);
```

## Analytics & Reporting

### Track Coupon Performance

```dart
final stats = await couponService.getCouponStats(couponId);
print('Total uses: ${stats['totalUses']}');
print('Revenue impact: \$${stats['totalRevenue']}');
```

### User Coupon History

```dart
final history = await subscriptionService.getUserCouponHistory();
for (final entry in history) {
  print('Used coupon: ${entry['couponCode']}');
  print('Saved: \$${entry['originalPrice'] - entry['discountedPrice']}');
}
```

## Security Considerations

1. **Code Generation**: Coupons use auto-generated unique codes
2. **Usage Limits**: Prevent abuse with configurable limits
3. **Expiration**: Time-based validity controls
4. **Ownership**: Coupons are tied to creating user
5. **Validation**: Server-side validation prevents tampering

## Best Practices

### For Beta Testing

```dart
await couponService.createFullAccessCoupon(
  title: 'Beta Access',
  description: 'Thank you for testing our app!',
  maxUses: 500,
  expiresAt: DateTime.now().add(Duration(days: 60)),
);
```

### For Referrals

```dart
await couponService.createFullAccessCoupon(
  title: 'Referral Bonus',
  description: 'Free access for successful referrals',
  maxUses: null, // Unlimited
  expiresAt: null, // No expiration
);
```

### For Limited-Time Offers

```dart
await couponService.createPercentageDiscountCoupon(
  title: 'Launch Special',
  description: '50% off for the first 30 days!',
  discountPercentage: 50,
  maxUses: 1000,
  expiresAt: DateTime.now().add(Duration(days: 30)),
);
```

## Integration Examples

See `coupon_integration_example.dart` for complete examples of:

- Subscription purchase flow with coupons
- Coupon validation and application
- Error handling and user feedback
- Admin coupon management

## Firebase Security Rules

Add these rules to secure coupon access:

```javascript
match /coupons/{couponId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null &&
    request.auth.uid == resource.data.createdBy;
}

match /subscriptions/{subscriptionId} {
  allow read, write: if request.auth != null &&
    request.auth.uid == resource.data.userId;
}
```

This coupon system provides a complete solution for promotional access while maintaining full analytics and control over your app's monetization strategy.
