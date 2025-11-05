# ArtBeat - Complete IAP SKU List for App Store Connect

## Overview

Create **18 IAP products** in your App Store Connect account:

- **6 consumable ad products** (banner and square ads)
- **4 consumable gift products** (gifts with credits)
- **8 auto-renewable subscription products** (artist subscriptions)

---

## SMALL Ads (Banner Format)

| SKU           | Display                    | Description                | Price     | Duration |
| ------------- | -------------------------- | -------------------------- | --------- | -------- |
| `ad_small_1w` | Small Banners - 7 Days     | 7-day small banner ads     | **$0.99** | 1 Week   |
| `ad_small_1m` | Small Banners - 1 Month    | 30-day small banner ads    | **$1.99** | 1 Month  |
| `ad_small_3m` | Small Banner Bundle - 3M   | 90-day small banner ads    | **$4.99** | 3 Months |

---

## BIG Ads (Square Format)

| SKU         | Display                    | Description                 | Price     | Duration |
| ----------- | -------------------------- | --------------------------- | --------- | -------- |
| `ad_big_1w` | Premium Squares - 7 Days   | 7-day premium square ads    | **$1.99** | 1 Week   |
| `ad_big_1m` | Premium Squares - 1 Month  | 30-day premium square ads   | **$3.99** | 1 Month  |
| `ad_big_3m` | Big Square Bundle - 3M     | 90-day premium square ads   | **$9.99** | 3 Months |

---

## GIFT Products (Consumable)

| SKU                     | Display               | Price     | Credits |
| ----------------------- | --------------------- | --------- | ------- |
| `artbeat_gift_small`    | Supporter Gift        | **$4.99** | 50      |
| `artbeat_gift_medium`   | Fan Gift              | **$9.99** | 100     |
| `artbeat_gift_large`    | Patron Gift           | **$24.99**| 250     |
| `artbeat_gift_premium`  | Benefactor Gift       | **$49.99**| 500     |

---

## ARTIST Subscriptions (Auto-Renewable)

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

### Gift Products (4 Consumables)

- **Users can gift appreciation to other artists** — consumable products (one-time purchase)
- Recipients receive platform credits for support and engagement
- Transparent pricing with clear credit amounts
- **Four tiers** allow varying levels of support (supporter → benefactor)
- Each gift is a distinct, itemized purchase with clear value

### Subscription Products (8 Auto-Renewable)

- **Clear tier differentiation** with distinct features and limits
- **Transparent pricing** with monthly/yearly options
- **Standard subscription model** for SaaS artist tools
- **Progressive feature unlocking** based on subscription tier
- **Industry-standard pricing** for creative professional tools
- Apple approves this model because subscriptions provide ongoing value to artists

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
