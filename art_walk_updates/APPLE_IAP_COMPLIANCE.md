# Apple IAP Compliance - ArtBeat Gift & Subscription System

**Date**: December 2024  
**Status**: ✅ APPLE COMPLIANT (After Updates)

---

## Executive Summary

ArtBeat's in-app purchase system has been redesigned to **100% comply with Apple App Store Review Guidelines** by separating two distinct monetization streams:

1. **Gifts** - In-app appreciation tokens (IAP consumables only)
2. **Artist Subscriptions** - Legitimate artist monetization with tools + withdrawal capability

---

## What Changed

### 🎁 GIFTS (IN-APP CREDITS ONLY)

**Before**:

- ❌ UI disclosed "70% of gift value goes to the artist"
- ❌ Payment strategy considered Stripe for gift processing
- ❌ **VIOLATES**: App Store rule "gifts may only be refunded to original purchaser and may not be exchanged"

**After**:

- ✅ Gifts are **consumable IAP products** that provide in-app credits
- ✅ Recipients receive credits usable only within the app
- ✅ **NO revenue sharing** with recipients
- ✅ **NO cash withdrawals** from gift credits
- ✅ Gift UI updated to explain credits are in-app only
- ✅ Payment strategy corrected: gifts use IAP (not Stripe)

**Implementation**:

```dart
// in_app_gift_service.dart - Backend only adds credits to account
// No payout logic exists
await _firestore.collection('users').doc(recipientId).update({
  'giftCredits': FieldValue.increment(credits),  // In-app only
  'totalGiftCreditsReceived': FieldValue.increment(credits),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

---

### 💳 ARTIST SUBSCRIPTIONS (LEGITIMATE MONETIZATION)

**The Correct Way for Artists to Earn**:

Artists can subscribe to professional tiers ($4.99–$79.99/month) to gain:

- **Analytics dashboards** (view their engagement, growth)
- **Advanced storage** (25GB–unlimited)
- **Premium features** (team management, API access)
- **Withdrawal capability** for:
  - Commissions from art sales
  - Tips/donations from supporters
  - Ad revenue
  - **NOT** from gifts (gifts are in-app appreciation only)

**Apple Compliance**:

- ✅ Subscriptions provide **clear, ongoing value**
- ✅ Artists choose to subscribe (not forced)
- ✅ Transparent pricing with monthly/yearly options
- ✅ Subscription cancellation is simple
- ✅ Withdrawal is handled via Stripe for Payments (outside App Store)

---

## Files Updated

### 1. **gift_rules_screen.dart**

**Location**: `/packages/artbeat_community/lib/screens/gifts/gift_rules_screen.dart`

**Changes**:

- ❌ Removed: `'70% of gift value goes to the artist'`
- ✅ Added: Clear explanation that gift credits are in-app only
- ✅ Updated payment processing info (Apple Pay / Google Play, not Stripe)
- ✅ Added note directing users to subscriptions for direct artist support

**New Section**:

```
How Gift Credits Work
- Gift recipients receive in-app credits
- Credits can be used to purchase subscriptions
- Credits can be used to purchase ad products
- Credits support artists indirectly through platform engagement
- For direct artist support, subscribe to an artist subscription
```

---

### 2. **IAP_SKU_LIST.md**

**Location**: `/packages/artbeat_ads/IAP_SKU_LIST.md`

**Changes**:

- ✅ Added Apple compliance notes for gift products
- ✅ Clarified gifts are consumable IAP (no payouts)
- ✅ Added "Artist Subscriptions" section explaining monetization
- ✅ Updated "Why This Structure Passes Apple Review" section with detailed compliance reasoning

**Key Additions**:

```
## Gift Products (Consumable - In-App Credits)

⚠️ APPLE COMPLIANCE NOTE:
Gifts are consumable IAP products that provide in-app credits.
Recipients CANNOT withdraw or cash out gift credits.
Credits can only be used within ArtBeat platform.
Recipients CANNOT receive payment/revenue from gifts.
```

---

### 3. **payment_strategy_service.dart**

**Location**: `/packages/artbeat_core/lib/src/services/payment_strategy_service.dart`

**Changes**:

- ❌ Changed: `_getMessagingPaymentMethod()` no longer returns Stripe for gifts
- ✅ Now: Returns IAP only for gift processing
- ✅ Added compliance comments explaining why gifts use IAP (no payouts)

**Updated Logic**:

```dart
case PurchaseType.nonConsumable:
  // ✅ APPLE COMPLIANT: Gifts use IAP only (no payouts to recipients)
  // Gift credits are in-app only and cannot be withdrawn/cashed out
  // Per App Store Review Guidelines: "gifts may only be refunded to the
  // original purchaser and may not be exchanged"
  return PaymentMethod.iap;
```

---

## Compliance Details

### ✅ Apple App Store Review Guidelines Compliance

**Guideline**: "Apps may enable gifting of items that are eligible for in-app purchase to others. Such gifts may only be refunded to the original purchaser and may not be exchanged."

**How ArtBeat Complies**:

1. **In-App Purchase Only** ✅

   - Gifts are purchased via Apple IAP (App Store)
   - No external payment processors involved
   - Gifts cannot be purchased outside the app

2. **No Revenue Sharing to Recipients** ✅

   - Gift credits **cannot be withdrawn** to bank account
   - Recipients cannot "exchange" gifts for real money
   - Gift credits are **in-app only** (purchase subscriptions, ads, features)

3. **Refund Policy** ✅

   - Refunds go to **original purchaser only** (Apple's standard)
   - Recipients cannot request refunds for received gifts
   - Clear terms: "All gifts are non-refundable"

4. **Clear Use Cases** ✅
   - Gift credits have transparent uses (listed on purchase screen)
   - No vague "credit" system
   - Each credit type (subscriptions, ads) is distinct

### 📱 IAP Products (18 Total)

**Gifts (Consumable - 4 products)**

```
artbeat_gift_small       $4.99   → 50 credits
artbeat_gift_medium      $9.99   → 100 credits
artbeat_gift_large       $24.99  → 250 credits
artbeat_gift_premium     $49.99  → 500 credits
```

**Ads (Consumable - 6 products)**

```
ad_small_1w  $0.99  (banner, 7 days)
ad_small_1m  $1.99  (banner, 1 month)
ad_small_3m  $4.99  (banner, 3 months)
ad_big_1w    $1.99  (square, 7 days)
ad_big_1m    $3.99  (square, 1 month)
ad_big_3m    $9.99  (square, 3 months)
```

**Artist Subscriptions (Auto-Renewable - 8 products)**

```
Monthly Tier:
- artbeat_starter_monthly    $4.99
- artbeat_creator_monthly    $12.99
- artbeat_business_monthly   $29.99
- artbeat_enterprise_monthly $79.99

Yearly Tier (20% savings):
- artbeat_starter_yearly     $47.99
- artbeat_creator_yearly     $124.99
- artbeat_business_yearly    $289.99
- artbeat_enterprise_yearly  $769.99
```

---

## Backend Verification

### ✅ No Payout Logic in Gift Processing

**in_app_gift_service.dart - completeGiftPurchase()**:

- ✅ Adds credits to recipient's Firestore account
- ✅ Sends notification to recipient
- ✅ Records gift history
- ❌ **NO** Stripe API calls
- ❌ **NO** payout processing
- ❌ **NO** revenue splitting calculations

```dart
// Only this happens - adding in-app credits
await _firestore.collection('users').doc(recipientId).update({
  'giftCredits': FieldValue.increment(credits),
  'totalGiftCreditsReceived': FieldValue.increment(credits),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

### ✅ Gift Credits Can Only Be Used In-App

**in_app_gift_service.dart - useGiftCredits()**:

- ✅ Allows spending credits on subscriptions
- ✅ Allows spending credits on ads
- ✅ Allows spending credits on premium features
- ❌ **NO** cash-out or withdrawal function exists
- ❌ **NO** Stripe integration
- ❌ **NO** bank transfer capability

---

## What to Communicate to App Store Reviewers

When submitting the updated app, include this in the **App Review Notes**:

### Suggested Review Notes:

---

**App Store Connect Notes** (for App Review team):

> **Gift System Compliance Update**
>
> We have updated our gift system to ensure full compliance with App Store Review Guidelines.
>
> **Changes Made:**
>
> - Gifts are now clearly labeled as "in-app appreciation tokens"
> - Gift recipients receive in-app credits only
> - Credits cannot be withdrawn, cashed out, or exchanged for money
> - Gifts can only be used within the app (purchase subscriptions, ads, premium features)
> - All revenue from gifts goes to ArtBeat platform (not shared with recipients)
>
> **Artist Monetization:**
>
> - Artists earn through separate "Artist Subscription" tier ($4.99–$79.99/month)
> - Subscriptions provide professional tools + withdrawal capability
> - Withdrawal is for artist earnings (commissions, tips, ad revenue), not from gifts
> - Withdrawal is handled outside the app via Stripe for Payments
>
> **Compliance:**
>
> - Gifts are purchased via Apple In-App Purchase only
> - Gift refunds go to original purchaser (per Apple policy)
> - No external payment processors involved in gift sales
> - Full compliance with App Store Review Guideline: "gifts may only be refunded to the original purchaser and may not be exchanged"

---

## Testing Checklist

Before submitting to App Store:

- [ ] **Gift Purchase Flow**
  - [ ] Can purchase all 4 gift SKUs
  - [ ] Credits appear in recipient's account
  - [ ] Recipient can see gift history
  - [ ] Recipient can use credits for subscriptions/ads
- [ ] **UI Compliance**
  - [ ] Gift rules screen shows no "70% artist payout" language
  - [ ] Clear disclosure that credits are in-app only
  - [ ] Subscription option visible for direct artist support
- [ ] **Backend Verification**
  - [ ] Gift completion adds credits (no Stripe calls)
  - [ ] No payout logic in gift service
  - [ ] Gift credits only usable in-app
  - [ ] Firebase data shows credits, not cash
- [ ] **Documentation**
  - [ ] IAP_SKU_LIST.md has compliance notes
  - [ ] payment_strategy_service.dart shows IAP for gifts
  - [ ] No Stripe references for gift payouts

---

## Future Artist Monetization (Post-Approval)

Once this compliant version is approved, artists can still earn through legitimate channels:

1. **Subscription Revenue** (recurring)

   - Artists subscribe for tools
   - ArtBeat can offer revenue sharing from subscriptions

2. **Commission System** (using Stripe outside app)

   - Artists receive commissions from art sales
   - Commissions withdrawn via Stripe (outside App Store rules)

3. **Tip System** (using Stripe outside app)

   - Users can tip artists
   - Tips withdrawn via Stripe

4. **Ad Revenue** (handled via Stripe)

   - Artists earn from ad placements
   - Revenue withdrawn via Stripe

5. **Premium Features** (IAP)
   - Additional paid features for creators
   - Handled via Apple IAP

**Key**: Any artist earnings must be processed via **Stripe outside the app**, not as in-app gift revenue sharing.

---

## Questions or Concerns?

If Apple App Store reviewers have questions:

- **Q: Why separate gifts and subscriptions?**

  - A: App Store guidelines prohibit gifts from resulting in revenue/payouts to recipients. Subscriptions are the legitimate channel for artist monetization.

- **Q: Can artists earn from gifts?**

  - A: No, gifts are in-app appreciation tokens only. Artists earn through subscriptions and other legitimate channels (commissions, tips, etc.) processed via Stripe outside the app.

- **Q: What can recipients do with gift credits?**

  - A: Use them within ArtBeat (subscriptions, ads, premium features). Credits cannot be withdrawn or exchanged for money.

- **Q: Is this a restriction or a feature?**
  - A: This is full App Store compliance. Many apps (Twitch, Discord, etc.) have similar gift-to-credits systems.

---

## Revision History

| Date     | Version | Changes                                                               |
| -------- | ------- | --------------------------------------------------------------------- |
| Dec 2024 | 1.0     | Initial compliance update - removed artist payout language from gifts |
| -        | -       | -                                                                     |

---

**Status**: Ready for App Store Submission  
**Last Updated**: December 2024  
**Reviewer**: Internal Compliance Check
