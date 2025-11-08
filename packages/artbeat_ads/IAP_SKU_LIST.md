# ArtBeat - Complete IAP SKU List for App Store Connect

## Overview

Create **18 IAP products** in your App Store Connect account:

- **6 consumable ad products** (banner and square ads)
- **4 consumable gift products** (gifts with credits)
- **8 auto-renewable subscription products** (artist subscriptions)

---

## SMALL Ads (Banner Format)

| SKU           | Display                  | Description             | Price     | Duration |
| ------------- | ------------------------ | ----------------------- | --------- | -------- |
| `ad_small_1w` | Small Banners - 7 Days   | 7-day small banner ads  | **$0.99** | 1 Week   |
| `ad_small_1m` | Small Banners - 1 Month  | 30-day small banner ads | **$1.99** | 1 Month  |
| `ad_small_3m` | Small Banner Bundle - 3M | 90-day small banner ads | **$4.99** | 3 Months |

---

## BIG Ads (Square Format)

| SKU         | Display                   | Description               | Price     | Duration |
| ----------- | ------------------------- | ------------------------- | --------- | -------- |
| `ad_big_1w` | Premium Squares - 7 Days  | 7-day premium square ads  | **$1.99** | 1 Week   |
| `ad_big_1m` | Premium Squares - 1 Month | 30-day premium square ads | **$3.99** | 1 Month  |
| `ad_big_3m` | Big Square Bundle - 3M    | 90-day premium square ads | **$9.99** | 3 Months |

---

## GIFT Products (Consumable - In-App Credits)

**⚠️ APPLE COMPLIANCE NOTE:**
Gifts are **consumable IAP products that provide in-app credits** to recipients.
Recipients **cannot withdraw or cash out** gift credits.
Credits can only be used within the ArtBeat platform for subscriptions, ads, and premium features.
Recipients **cannot receive payment/revenue** from gifts (see Artist Subscriptions for legitimate artist monetization).

| SKU                    | Display         | Price      | Credits | Usage                                         |
| ---------------------- | --------------- | ---------- | ------- | --------------------------------------------- |
| `artbeat_gift_small`   | Supporter Gift  | **$4.99**  | 50      | Purchase subscriptions, ads, premium features |
| `artbeat_gift_medium`  | Fan Gift        | **$9.99**  | 100     | Purchase subscriptions, ads, premium features |
| `artbeat_gift_large`   | Patron Gift     | **$24.99** | 250     | Purchase subscriptions, ads, premium features |
| `artbeat_gift_premium` | Benefactor Gift | **$49.99** | 500     | Purchase subscriptions, ads, premium features |

---

## ARTIST Revenue Streams (Direct Artist Income)

**⚠️ IMPORTANT:** Artist Subscriptions (below) are **app fees artists pay** to unlock tools. This is **ArtBeat platform revenue**, not artist earnings.

Artists earn direct income through **3 separate channels** (all via Stripe payouts to bank account):

### 1. Commissions & Sales (Stripe-Based) - **Variable Artist Income**

Artists can sell artwork and commissions directly through ArtBeat. Buyers pay via **Stripe** (not IAP).

- Artists set their own commission rates
- ArtBeat platform fee: 8–15% (configurable per tier)
- Artist receives payout to bank account via Stripe
- Fully compliant (seller/buyer transaction, not gifting)

### 2. Tips & Donations (Stripe-Based) - **Variable Artist Income**

Supporters can tip artists on their artwork and profiles via **Stripe** (not IAP).

- Tipsters choose any amount ($1–$100+)
- Artists receive 90–95% (platform keeps 5–10%)
- Fully compliant (direct support, not gifting)

### 3. Ad Revenue (Contextual Ads) - **Variable Artist Income**

Artists earn when ads appear on their content (artist profiles, artworks, galleries).

- Revenue share: 50–70% to artists, 30–50% to platform
- Buyers purchase ad slots via consumable IAP (see Ad Products section)
- Artists with higher visibility/engagement earn more

---

## Revenue Model Clarity

**ARTBEAT Revenue** (Platform):

- Artists pay $4.99–$79.99/month for subscriptions (tools, storage, analytics)
- App sells ads (consumable IAP)
- App sells gifts (consumable IAP)
- App takes 8–15% cut of commissions, 5–10% cut of tips, 30–50% of ad revenue

**ARTIST Revenue** (Direct Income via Stripe):

- Commissions from art sales
- Tips/donations from supporters
- Ad revenue share
- **NOT from gifts** (gifts are in-app appreciation tokens only)

**Example Flow:**

- Supporter buys $9.99 gift → Recipient gets 100 in-app credits → **ArtBeat gets $9.99**
- Artist pays $4.99 for Artist Starter subscription → **ArtBeat gets $4.99**
- Artist sells a $50 commission → **Artist gets $42.50–$46 (after ArtBeat fee)**
- Supporter tips artist $5 → **Artist gets $4.50–$4.75**
- 100 ads run on artist's gallery → **Artist gets ad revenue share via Stripe payout**

### Monthly Subscriptions

| SKU                          | Display                     | Price      | Features                                            |
| ---------------------------- | --------------------------- | ---------- | --------------------------------------------------- |
| `artbeat_starter_monthly`    | Artist Starter - Monthly    | **$4.99**  | 25 artworks, 5GB storage, basic analytics           |
| `artbeat_creator_monthly`    | Artist Creator - Monthly    | **$12.99** | 100 artworks, 25GB storage, advanced features       |
| `artbeat_business_monthly`   | Artist Business - Monthly   | **$29.99** | Unlimited artworks, team features, API access       |
| `artbeat_enterprise_monthly` | Artist Enterprise - Monthly | **$79.99** | Enterprise features, white-label, dedicated support |

### Yearly Subscriptions (20% savings)

| SKU                         | Display                    | Price       | Savings            |
| --------------------------- | -------------------------- | ----------- | ------------------ |
| `artbeat_starter_yearly`    | Artist Starter - Yearly    | **$47.99**  | Save $12 per year  |
| `artbeat_creator_yearly`    | Artist Creator - Yearly    | **$124.99** | Save $31 per year  |
| `artbeat_business_yearly`   | Artist Business - Yearly   | **$289.99** | Save $72 per year  |
| `artbeat_enterprise_yearly` | Artist Enterprise - Yearly | **$769.99** | Save $192 per year |

---

## Platform Configuration Summary

| Revenue Stream           | Who Pays      | Platform    | Product Type        | Setup Location                  | Goes To             |
| ------------------------ | ------------- | ----------- | ------------------- | ------------------------------- | ------------------- |
| **Ads**                  | Users/Artists | iOS/Android | Consumable IAP      | App Store Connect / Google Play | **ArtBeat**         |
| **Gifts**                | Gift Senders  | iOS/Android | Consumable IAP      | App Store Connect / Google Play | **ArtBeat**         |
| **Artist Subscriptions** | Artists       | iOS/Android | Auto-Renewable IAP  | App Store Connect / Google Play | **ArtBeat**         |
| **Commissions & Sales**  | Buyers        | Stripe      | Direct Seller/Buyer | Stripe Dashboard                | **Artist** (90%+)   |
| **Tips & Donations**     | Supporters    | Stripe      | Direct Support      | Stripe Dashboard                | **Artist** (90–95%) |
| **Ad Revenue Share**     | (from Ads)    | Stripe      | Artist Payout       | Stripe Dashboard                | **Artist** (50–70%) |

---

## How to Set Up in App Store Connect

### iOS (App Store Connect)

#### For Ad Products (Consumable)

1. Go to **My Apps** → Select your app
2. Navigate to **In-App Purchases**
3. For each ad SKU:
   - Click **Create In-App Purchase**
   - Select **Consumable** (not Renewable Subscription)
   - Enter the **SKU** exactly as listed
   - Set **Reference Name** to match the SKU
   - Set **Price Tier** to match the pricing
   - Fill in metadata (description, screenshot, etc.)
   - Save and submit for review

#### For Gift Products (Consumable)

1. Go to **My Apps** → Select your app
2. Navigate to **In-App Purchases**
3. For each gift SKU:
   - Click **Create In-App Purchase**
   - Select **Consumable** (not Renewable Subscription)
   - Enter the **SKU** exactly as listed (e.g., `artbeat_gift_small`)
   - Set **Reference Name** to match the SKU
   - Set **Price Tier** to match the pricing
   - Fill in metadata with gift tier description and credit amount
   - Save and submit for review

#### For Subscription Products (Auto-Renewable)

1. Go to **My Apps** → Select your app
2. Navigate to **Subscriptions**
3. Click **Create Subscription Group** (name it "Artist Subscriptions")
4. For each subscription SKU:
   - Click **Create Subscription**
   - Select the subscription group created above
   - Enter the **SKU** exactly as listed
   - Set **Reference Name** to match the SKU
   - Set **Subscription Duration** (1 month or 1 year)
   - Set **Price Tier** to match the pricing
   - Configure **Subscription Localizations**
   - Fill in metadata and promotional images
   - Save and submit for review

### Android (Google Play Console)

#### For Ad Products (Managed Products)

1. Go to your app → **Monetize** → **In-app products**
2. For each ad SKU:
   - Click **Create product**
   - Select **Managed product** (not subscription)
   - Enter the **Product ID** exactly as the SKU
   - Set **Default price** to match the pricing
   - Activate the product
   - Save

#### For Gift Products (Managed Products)

1. Go to your app → **Monetize** → **In-app products**
2. For each gift SKU:
   - Click **Create product**
   - Select **Managed product** (not subscription)
   - Enter the **Product ID** exactly as the SKU (e.g., `artbeat_gift_small`)
   - Set **Default price** to match the pricing
   - Add description including credit amount
   - Activate the product
   - Save

#### For Subscription Products

1. Go to your app → **Monetize** → **Subscriptions**
2. For each subscription SKU:
   - Click **Create subscription**
   - Enter the **Product ID** exactly as the SKU
   - Set **Base plan** with appropriate duration (1 month or 1 year)
   - Set **Default price** to match the pricing
   - Configure **Subscription benefits**
   - Activate the subscription
   - Save

---

## Quick Copy-Paste Lists

### All Ad SKUs (6 products)

```
ad_small_1w
ad_small_1m
ad_small_3m
ad_big_1w
ad_big_1m
ad_big_3m
```

### All Gift SKUs (4 products)

```
artbeat_gift_small
artbeat_gift_medium
artbeat_gift_large
artbeat_gift_premium
```

### All Subscription SKUs (8 products)

```
artbeat_starter_monthly
artbeat_creator_monthly
artbeat_business_monthly
artbeat_enterprise_monthly
artbeat_starter_yearly
artbeat_creator_yearly
artbeat_business_yearly
artbeat_enterprise_yearly
```

### All SKUs Combined (18 total products)

```
ad_small_1w
ad_small_1m
ad_small_3m
ad_big_1w
ad_big_1m
ad_big_3m
artbeat_gift_small
artbeat_gift_medium
artbeat_gift_large
artbeat_gift_premium
artbeat_starter_monthly
artbeat_creator_monthly
artbeat_business_monthly
artbeat_enterprise_monthly
artbeat_starter_yearly
artbeat_creator_yearly
artbeat_business_yearly
artbeat_enterprise_yearly
```

### CSV Format (for bulk import if supported)

#### Ad Products (Consumable)

```
SKU,Product Type,Price (USD),Display Name
ad_small_1w,Consumable,0.99,Small Banner - 1 Week
ad_small_1m,Consumable,1.99,Small Banner - 1 Month
ad_small_3m,Consumable,4.99,Small Banner - 3 Months
ad_big_1w,Consumable,1.99,Big Square - 1 Week
ad_big_1m,Consumable,3.99,Big Square - 1 Month
ad_big_3m,Consumable,9.99,Big Square - 3 Months
```

#### Gift Products (Consumable)

```
SKU,Product Type,Price (USD),Display Name,Credits
artbeat_gift_small,Consumable,4.99,Supporter Gift,50
artbeat_gift_medium,Consumable,9.99,Fan Gift,100
artbeat_gift_large,Consumable,24.99,Patron Gift,250
artbeat_gift_premium,Consumable,49.99,Benefactor Gift,500
```

#### Subscription Products (Auto-Renewable)

```
SKU,Product Type,Price (USD),Display Name
artbeat_starter_monthly,Auto-Renewable Subscription,4.99,Artist Starter - Monthly
artbeat_creator_monthly,Auto-Renewable Subscription,12.99,Artist Creator - Monthly
artbeat_business_monthly,Auto-Renewable Subscription,29.99,Artist Business - Monthly
artbeat_enterprise_monthly,Auto-Renewable Subscription,79.99,Artist Enterprise - Monthly
artbeat_starter_yearly,Auto-Renewable Subscription,47.99,Artist Starter - Yearly
artbeat_creator_yearly,Auto-Renewable Subscription,124.99,Artist Creator - Yearly
artbeat_business_yearly,Auto-Renewable Subscription,289.99,Artist Business - Yearly
artbeat_enterprise_yearly,Auto-Renewable Subscription,769.99,Artist Enterprise - Yearly
```

---

## Why This Structure Passes Apple Review

### Ad Products (6 Consumables)

- **Each product is a distinct, itemized purchase** — not a "generic credit" system
- Users see exactly what they're buying: size × duration
- The pricing is transparent and varies by configuration
- All ad products are **consumable** (one-time purchase per ad)
- Simple enough for local advertisers to understand in seconds

### Gift Products (4 Consumables) - IN-APP CREDITS ONLY

**Apple Compliance Details:**

- **Gifts are consumable items** that provide in-app credits to recipients
- **NO revenue sharing/payouts to recipients** — gifts do NOT result in cash or platform payouts
- Recipients can **only use credits within the app** (subscriptions, ads, premium features)
- Credits **cannot be withdrawn, refunded (except to sender), or exchanged for money**
- Senders cannot receive money from gifts — they're purely for in-app appreciation
- Per App Store Review Guidelines: "Apps may enable gifting of items...gifts may only be refunded to the original purchaser and may not be exchanged"

### Subscription Products (8 Auto-Renewable) - APP PLATFORM REVENUE

**Apple Compliance Details:**

- **Subscriptions are app fees artists pay** to unlock professional tools and features
  - Professional tooling (analytics, storage, advanced features)
  - Higher storage/upload limits
  - Premium profile visibility and team collaboration
  - Unlock commission/tip withdrawal capabilities (Stripe payouts)
- **Clear, distinct tiers** with progressive feature unlocking
- **Transparent pricing** with standard industry rates
- **This is ArtBeat platform revenue**, NOT artist earnings

**Artist Earnings** (separate, via Stripe only):

1. **Commission/Sales via Stripe** (variable) — Seller/buyer transactions → Artist gets 85–92%
2. **Tips/Donations via Stripe** (variable) — Direct fan support → Artist gets 90–95%
3. **Ad Revenue via Stripe** (variable) — Earn when ads display on their content → Artist gets 50–70%
4. **NOT from gifts** — Gifts provide in-app credits only (Apple compliant, no payouts)

---

## Testing

### iOS StoreKit Testing

1. In Xcode: **Product** → **Scheme** → **Edit Scheme**
2. Select **Run** → **Options** → **StoreKit Configuration**
3. Create a test configuration file with all 14 SKUs
4. Add both consumable products (ads) and subscription products (artist subscriptions)
5. For subscriptions, set test durations (e.g., 5 minutes = 1 month) for faster testing
6. Products will be available for testing without real charges

### Android Testing

1. Add test accounts in Google Play Console
2. Install the signed APK on a test device
3. Use Google Play's sandbox environment for testing
4. For subscriptions, add test accounts to enable special test pricing
5. All products will appear in the app without real charges

### Subscription Testing Notes

- Test subscription upgrades/downgrades between tiers
- Test monthly to yearly plan changes
- Verify subscription cancellation and renewal flows
- Test subscription restoration on app reinstall

---

## Pricing Justification

### Ad Products

- **Small Banner (1 week)**: $0.99 — budget-friendly entry
- **Big Square (1 week)**: $1.99 — premium placement bump
- **3-Month discount**: Lower per-week rate ($1.66/week for small, $3.33/week for big)
- Competitive and easy for local Kinston advertisers to understand and budget for

### Subscription Products

- **Starter ($4.99/month)**: Entry-level for emerging artists, competitive with basic creative tools
- **Creator ($12.99/month)**: Mid-tier professional features, comparable to Adobe Creative Cloud individual plans
- **Business ($29.99/month)**: Team and business features, standard SaaS business tier pricing
- **Enterprise ($79.99/month)**: Premium enterprise features, justified by white-label and dedicated support
- **Yearly plans**: 20% discount encourages long-term commitment, standard in subscription pricing

### Full Artist Monetization Model

**Artist Journey & Revenue Streams:**

1. **Entry level (Free tier)**:

   - Artists can post work, gain followers
   - Can receive tips (Stripe) — keep 90–95%
   - Can receive commissions (Stripe) — keep 85–92%
   - Can earn ad revenue (Stripe) — keep 50–70%

2. **Growth (Artist Starter $4.99/mo)**:

   - **Pays ArtBeat** $4.99 for tools/storage/analytics
   - Same earning channels as above, but with better tools

3. **Scale (Creator+ $12.99–$79.99/mo)**:
   - **Pays ArtBeat** $12.99–$79.99 for professional tooling
   - Full commission management, team features, API access
   - Same earning channels with premium features

**Artist Income Sources (ALL via Stripe):**

- Commissions from artwork sales → Keep 85–92%
- Tips/donations from supporters → Keep 90–95%
- Ad revenue when ads display on galleries → Keep 50–70%
- **NOT from gifts** (gifts are in-app credits, no payouts)

**Why this model works:**

- Similar to Patreon (creators pay for tools/visibility) + Etsy (commissions) + YouTube (ad revenue)
- Artists can earn even on free tier (commissions + tips + ads)
- Artists who want advanced tools pay subscription fee
- Fully compliant with Apple/Google App Store policies
- No "pay to win" mechanics (artists don't need to buy anything to succeed)
