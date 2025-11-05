# Implementation Guides - App Store Requirements

## Guide 1: Creating 18 Unique Promotional Images (Guideline 2.3.2)

### Overview
Each of your 18 IAP products requires a unique promotional image (1200 x 600 pixels) that clearly represents what users are purchasing. The App Store rejected the submission because promotional images were either duplicates or identical to the app icon. Each image must be visually distinct and accurately represent its associated IAP product.

### Image Specifications
- **Dimensions**: 1200 x 600 pixels (2:1 aspect ratio)
- **Format**: PNG or JPG
- **Color Space**: RGB (sRGB)
- **File Size**: Under 1 MB recommended
- **Design**: Must clearly differentiate from all other promotional images and the app icon

### The 18 Promotional Images - Specific Design Guide

#### Small Banner Products (6 total)
These images should prominently feature a small banner icon/graphic. Vary the duration/timeframe visually.

1. **Small Banners - 7 Days**
   - Design: Small banner graphic with "7 DAYS" text prominently displayed
   - Color scheme: Primary color variation (e.g., light blue)
   - Visual elements: Calendar indicator showing short duration

2. **Small Banners - 1 Month**
   - Design: Small banner graphic with "1 MONTH" text prominently displayed
   - Color scheme: Different from 7 Days (e.g., mint green)
   - Visual elements: Calendar with 4-week indicator

3. **Small Banners - 3 Months**
   - Design: Small banner graphic with "3 MONTHS" text prominently displayed
   - Color scheme: Different from previous two (e.g., coral/orange)
   - Visual elements: Calendar spanning 12 weeks

4. **Small Banners - 1 Year**
   - Design: Small banner graphic with "1 YEAR" text prominently displayed
   - Color scheme: Premium feel (e.g., gold/yellow)
   - Visual elements: Full year calendar or annual badge

5. **Small Banner Bundle - 3 Months**
   - Design: Small banner graphic with "BUNDLE 3M" or "3M BUNDLE" text
   - Color scheme: Distinctly different - show bundled concept (e.g., purple with multiple layers)
   - Visual elements: Overlapping banners or stacked appearance to show bundle

6. **Small Banner Bundle - Lifetime**
   - Design: Small banner graphic with "LIFETIME" text prominently displayed
   - Color scheme: Premium/exclusive feel (e.g., silver/white with gold accents)
   - Visual elements: Infinity symbol or "forever" indicator

#### Big Square Products (6 total)
These images should prominently feature a larger square banner icon/graphic. Use distinctly different color schemes and duration indicators from small banners.

7. **Big Square - 7 Days**
   - Design: Large square banner graphic with "7 DAYS" text prominently displayed
   - Color scheme: Different from Small Banner 7 Days (e.g., deep blue instead of light blue)
   - Visual elements: Bold square shape, calendar with "7" indicator

8. **Big Square - 1 Month**
   - Design: Large square banner graphic with "1 MONTH" text prominently displayed
   - Color scheme: Different from Small Banner 1 Month (e.g., teal instead of mint)
   - Visual elements: Bold square shape, month badge

9. **Big Square - 3 Months**
   - Design: Large square banner graphic with "3 MONTHS" text prominently displayed
   - Color scheme: Different from Small Banner 3 Months (e.g., burgundy instead of coral)
   - Visual elements: Bold square shape, triple-segment indicator

10. **Big Square - 1 Year**
    - Design: Large square banner graphic with "1 YEAR" text prominently displayed
    - Color scheme: Different from Small Banner 1 Year (e.g., rose gold instead of gold)
    - Visual elements: Bold square shape, annual badge with crown/premium indicator

11. **Big Square Bundle - 3 Months**
    - Design: Large square banner graphic with "BUNDLE 3M" or "3M BUNDLE" text
    - Color scheme: Distinctly different from Small Banner Bundle 3M (e.g., deep purple with vibrant accents)
    - Visual elements: Multiple overlapping squares or mosaic pattern to show bundle

12. **Big Square Bundle - Lifetime**
    - Design: Large square banner graphic with "LIFETIME" text prominently displayed
    - Color scheme: Premium/exclusive, different from Small Banner Bundle Lifetime (e.g., platinum/dark silver)
    - Visual elements: Large bold square, infinity symbol, VIP or premium crown

#### Flexible Banner Products (6 total)
These images should showcase a flexible/adaptable banner concept with duration indicators.

13. **Flexible Banners - 1 Month**
    - Design: Flexible/scrolling banner concept with "1 MONTH" text
    - Color scheme: Energetic and dynamic (e.g., bright green or lime)
    - Visual elements: Animated or flowing banner appearance, flexible curves

14. **Flexible Banners - 3 Months**
    - Design: Flexible/scrolling banner concept with "3 MONTHS" text
    - Color scheme: Different energetic color (e.g., electric blue)
    - Visual elements: Flowing/flexible appearance, triple-segment division

15. **Flexible Banners - 6 Months**
    - Design: Flexible/scrolling banner concept with "6 MONTHS" text
    - Color scheme: Different energetic color (e.g., vibrant orange)
    - Visual elements: Flowing appearance, six-segment or extended indicator

16. **Flexible Banners - 1 Year**
    - Design: Flexible/scrolling banner concept with "1 YEAR" text
    - Color scheme: Premium energetic (e.g., bright gold or magenta)
    - Visual elements: Flowing appearance, annual scale or continuous loop indicator

17. **Flexible Banner Bundle - 6 Months**
    - Design: Flexible/scrolling banner concept with "BUNDLE 6M" or "6M BUNDLE" text
    - Color scheme: Distinct bundle appearance (e.g., multi-colored gradient or layered purple)
    - Visual elements: Multiple flexible banners stacked/layered to show bundle concept

18. **Flexible Banner Bundle - 1 Year**
    - Design: Flexible/scrolling banner concept with "BUNDLE 1Y" or "1Y BUNDLE" text
    - Color scheme: Premium multi-color or gradient (e.g., rainbow gradient or metallic spectrum)
    - Visual elements: Multiple flexible banners, annual scale, VIP or premium indicators

### Design Best Practices
- **Consistency**: Use your app's branding colors as a base but create 18 distinct variations
- **Clarity**: Duration or bundle type must be immediately clear from the image
- **Differentiation**: Never use the same background color combination, layout, or visual hierarchy twice
- **Hierarchy**: Product type (Small Banner, Big Square, Flexible Banner) should be visually distinct
- **Typography**: Use bold, readable fonts with strong contrast against background
- **Avoid**: Don't use app icon elements, duplicate layouts, or ambiguous graphics

### Implementation Steps
1. Create a design system/template in Figma or Adobe Creative Suite with base dimensions (1200 x 600)
2. Design the Small Banner series first (6 images) with distinct color palette
3. Design the Big Square series (6 images) with a second distinct color palette
4. Design the Flexible Banner series (6 images) with a third distinct color palette
5. Export all 18 images as PNG files (1200 x 600 pixels each)
6. Name files clearly: `small-banner-7-days.png`, `big-square-1-month.png`, etc.
7. Upload each image to App Store Connect, associating it with the correct IAP product
8. Verify in App Store Connect that all 18 images are displayed and visually distinct
9. Take screenshots of each promotional image in App Store Connect for documentation
10. Submit images to Apple App Store for review

---

## Guide 2: Verifying IAP Products in App Store Connect Sandbox (Guideline 2.1)

### Overview
Apple's review team cannot locate or test your 18 IAP products in the sandbox environment. This guide provides step-by-step instructions to verify that each IAP product is properly configured, accessible in the sandbox, and functioning correctly for testers.

### Prerequisites
- Access to App Store Connect with Admin or Finance privileges
- Sandbox Apple ID account (separate from your production Apple ID)
- Device running iOS/iPadOS with the app installed from TestFlight or Xcode
- All 18 IAP products created in App Store Connect

### Part 1: Verify IAP Product Configuration in App Store Connect

#### Step 1: Access In-App Purchases
1. Log into [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app "ArtBeat"
3. Navigate to **General** → **In-App Purchases**
4. Verify you see all 18 products listed

#### Step 2: Verify Each Product Configuration
For each of the 18 IAP products below, complete the verification steps:

**Small Banner Products:**

1. **Small Banners - 7 Days**
   - Product ID: (verify matches code: e.g., `com.artbeat.small_banner_7d`)
   - Type: Consumable (if repurchasable) or Non-consumable (if one-time)
   - Reference Name: "Small Banners - 7 Days"
   - Display Name: "Small Banners - 7 Days" (max 30 characters)
   - Description: Clearly describes 7-day duration and banner count
   - Price Tier: Verify price is set (not empty)
   - Sandbox: Enabled ✓
   - Localization: Default language localized

2. **Small Banners - 1 Month**
   - Product ID: `com.artbeat.small_banner_1m`
   - Type: Verify consistent with business model
   - Display Name: "Small Banners - 1 Month"
   - Description: Clearly differentiates from 7-day version (mention "30 days" or "1 month")
   - Price Tier: Verify price is set and different from 7-day if expected
   - Sandbox: Enabled ✓

3. **Small Banners - 3 Months**
   - Product ID: `com.artbeat.small_banner_3m`
   - Type: Consistent with other small banner products
   - Display Name: "Small Banners - 3 Months"
   - Description: Clearly indicates 3-month duration, price advantage over shorter plans
   - Price Tier: Verify appropriate pricing
   - Sandbox: Enabled ✓

4. **Small Banners - 1 Year**
   - Product ID: `com.artbeat.small_banner_1y`
   - Type: Consistent configuration
   - Display Name: "Small Banners - 1 Year"
   - Description: Indicates annual duration and best value positioning
   - Price Tier: Verify annual pricing
   - Sandbox: Enabled ✓

5. **Small Banner Bundle - 3 Months**
   - Product ID: `com.artbeat.small_banner_bundle_3m`
   - Type: Verify matches code implementation
   - Display Name: "Small Banner Bundle - 3 Months"
   - Description: Clearly indicates bundle (multiple banner types) and 3-month duration
   - Price Tier: Verify shows bundle value (lower than individual purchases)
   - Sandbox: Enabled ✓

6. **Small Banner Bundle - Lifetime**
   - Product ID: `com.artbeat.small_banner_bundle_lifetime`
   - Type: Non-consumable (typically lifetime)
   - Display Name: "Small Banner Bundle - Lifetime"
   - Description: Indicates permanent access, all banner types included
   - Price Tier: Verify premium pricing for lifetime access
   - Sandbox: Enabled ✓

**Big Square Products:**

7. **Big Square - 7 Days**
   - Product ID: `com.artbeat.big_square_7d`
   - Type: Match small banner configuration approach
   - Display Name: "Big Square - 7 Days"
   - Description: Mentions "bigger" or "large" square banners, 7-day duration
   - Price Tier: Typically higher than small banner equivalent
   - Sandbox: Enabled ✓

8. **Big Square - 1 Month**
   - Product ID: `com.artbeat.big_square_1m`
   - Type: Consistent
   - Display Name: "Big Square - 1 Month"
   - Description: Indicates large square banners, 1-month access
   - Price Tier: Verify appropriate tier
   - Sandbox: Enabled ✓

9. **Big Square - 3 Months**
   - Product ID: `com.artbeat.big_square_3m`
   - Type: Consistent
   - Display Name: "Big Square - 3 Months"
   - Description: Large square banners, 3-month duration
   - Price Tier: Verify pricing
   - Sandbox: Enabled ✓

10. **Big Square - 1 Year**
    - Product ID: `com.artbeat.big_square_1y`
    - Type: Consistent
    - Display Name: "Big Square - 1 Year"
    - Description: Large square banners, annual access
    - Price Tier: Annual pricing
    - Sandbox: Enabled ✓

11. **Big Square Bundle - 3 Months**
    - Product ID: `com.artbeat.big_square_bundle_3m`
    - Type: Match bundle configuration
    - Display Name: "Big Square Bundle - 3 Months"
    - Description: Bundle of large square banners, 3-month duration
    - Price Tier: Bundle pricing (value over individual)
    - Sandbox: Enabled ✓

12. **Big Square Bundle - Lifetime**
    - Product ID: `com.artbeat.big_square_bundle_lifetime`
    - Type: Non-consumable (lifetime)
    - Display Name: "Big Square Bundle - Lifetime"
    - Description: All large square banners, permanent access
    - Price Tier: Premium lifetime pricing
    - Sandbox: Enabled ✓

**Flexible Banner Products:**

13. **Flexible Banners - 1 Month**
    - Product ID: `com.artbeat.flexible_banner_1m`
    - Type: Consumable or time-limited
    - Display Name: "Flexible Banners - 1 Month"
    - Description: Flexible/scrollable banners, 1-month access
    - Price Tier: Verify pricing tier
    - Sandbox: Enabled ✓

14. **Flexible Banners - 3 Months**
    - Product ID: `com.artbeat.flexible_banner_3m`
    - Type: Consistent
    - Display Name: "Flexible Banners - 3 Months"
    - Description: Flexible banners, 3-month duration
    - Price Tier: Verify pricing
    - Sandbox: Enabled ✓

15. **Flexible Banners - 6 Months**
    - Product ID: `com.artbeat.flexible_banner_6m`
    - Type: Consistent
    - Display Name: "Flexible Banners - 6 Months"
    - Description: Flexible banners, 6-month access, value pricing
    - Price Tier: 6-month pricing
    - Sandbox: Enabled ✓

16. **Flexible Banners - 1 Year**
    - Product ID: `com.artbeat.flexible_banner_1y`
    - Type: Consistent
    - Display Name: "Flexible Banners - 1 Year"
    - Description: Flexible banners, annual access, best value
    - Price Tier: Annual pricing
    - Sandbox: Enabled ✓

17. **Flexible Banner Bundle - 6 Months**
    - Product ID: `com.artbeat.flexible_banner_bundle_6m`
    - Type: Bundle type (match other bundles)
    - Display Name: "Flexible Banner Bundle - 6 Months"
    - Description: Bundle of flexible banners, 6-month duration
    - Price Tier: Bundle value pricing
    - Sandbox: Enabled ✓

18. **Flexible Banner Bundle - 1 Year**
    - Product ID: `com.artbeat.flexible_banner_bundle_1y`
    - Type: Bundle type (non-consumable for long-term)
    - Display Name: "Flexible Banner Bundle - 1 Year"
    - Description: All flexible banners, annual access, premium bundle
    - Price Tier: Premium bundle pricing
    - Sandbox: Enabled ✓

### Part 2: Verify Sandbox Account and Permissions

#### Step 1: Verify Sandbox Account is Created
1. In App Store Connect, go to **Users and Access** → **Sandbox Testers**
2. Verify you have at least one sandbox tester account created
3. If not created, click **+** and create a new sandbox tester:
   - Email: (use a test email you control, e.g., `artbeat-test@example.com`)
   - First Name: "Sandbox"
   - Last Name: "Tester"
   - Password: (create strong password)
4. Save and note the credentials

#### Step 2: Verify Paid Apps Agreement Acceptance
1. In App Store Connect, go to **Agreements, Tax, and Banking** → **Agreements**
2. Under "iOS Apps", verify the **Paid Apps Agreement** shows: "Accepted"
3. If not accepted:
   - Click on the agreement
   - Review and accept the Paid Apps Agreement
   - This is REQUIRED for any IAP to function, including in sandbox
4. Wait up to 24 hours for Agreement acceptance to propagate (usually immediate)

#### Step 3: Verify Account Holder Information
1. Go to **Account Holders** section
2. Verify Account Holder name and contact information are complete
3. Verify at least one payment method is on file

### Part 3: Test Each IAP in Sandbox Environment

#### Step 1: Prepare Test Device
1. On your iOS test device, sign out of App Store:
   - Settings → App Store → (tap your account) → Sign Out
2. Add the sandbox tester account:
   - Settings → App Store → "Sign in"
   - Enter sandbox tester email and password
   - Complete any verification steps
3. Install ArtBeat app from TestFlight or Xcode

#### Step 2: Test Access to IAP in App
1. Launch ArtBeat app on your test device
2. Navigate to the store/purchase screen where IAPs are displayed
3. For each of the 18 IAP products, verify:
   - Product name displays correctly
   - Product description displays correctly
   - Product price displays (sandbox prices typically show as $0.99, $1.99, etc.)
   - Product image/icon displays correctly
   - Product is tappable/selectable

#### Step 3: Complete a Test Purchase for Each Product Type
Choose one representative product from each category and complete a purchase:

1. **Test Small Banners - 1 Month purchase:**
   - Tap the product in the app
   - Confirm purchase dialog appears
   - Complete purchase (sandbox won't charge real money)
   - Verify "Thank you for your purchase" message appears
   - Verify the banner/benefit appears in app after purchase

2. **Test Big Square - 1 Month purchase:**
   - Repeat same process to verify big square IAPs work

3. **Test Flexible Banners - 1 Month purchase:**
   - Repeat same process to verify flexible banner IAPs work

4. **Test Bundle product:**
   - Tap the bundle product
   - Verify bundle contents are displayed (all items included)
   - Complete purchase
   - Verify all bundle items are unlocked

#### Step 4: Verify Restore Purchases
1. Navigate to any "Restore Purchases" button in the app
2. Tap it
3. Verify previously purchased items are restored and re-shown as owned

### Part 4: Document Configuration for Apple Review

#### Create Verification Checklist
Document the following for submission to Apple:

**Store Location Instructions:**
1. After signing in with the provided sandbox account, launch the app
2. Navigate to: [specify your app's purchase flow, e.g., "Profile → Premium Features" or "Main Menu → Shop"]
3. The user will see all 18 IAP products available for purchase
4. All products are grouped by type: Small Banners, Big Squares, and Flexible Banners
5. Each product shows duration (7 days, 1 month, 3 months, 1 year, lifetime) and bundle status

**Product Access:**
- Small Banners (6 products): [Duration options with bundle]
- Big Squares (6 products): [Duration options with bundle]
- Flexible Banners (6 products): [Duration options with bundle]

**Sandbox Tester Account:**
- Email: [your sandbox email]
- Password: [your sandbox password]
- Note: This account only works in sandbox environment

**Testing Steps for Reviewer:**
1. Sign out of App Store on test device
2. Sign in with provided sandbox account
3. Launch ArtBeat and navigate to shop
4. Tap any IAP product (e.g., "Small Banners - 1 Month")
5. Complete the test purchase (no actual charge in sandbox)
6. Verify purchase confirmation appears in app
7. Verify benefit becomes active (e.g., banners display)
8. Repeat with 2-3 different products to verify all work

### Part 5: Submit Configuration Details to Apple

In App Store Connect, reply to the review message with:

```
Dear Apple Review Team,

Thank you for your review. We have verified that all 18 in-app purchase products are properly configured and accessible in the sandbox environment.

SANDBOX VERIFICATION DETAILS:

1. All 18 IAP products are enabled for sandbox testing
2. The Paid Apps Agreement has been accepted
3. Account holder information is complete
4. A sandbox tester account has been created for your review

STORE LOCATION AND NAVIGATION:
[App Name] → [Screen/Tab where IAPs are displayed]

The app displays all 18 IAP products organized by type:
- 6 Small Banner products (7 days, 1 month, 3 months, 1 year, 3M bundle, lifetime bundle)
- 6 Big Square products (7 days, 1 month, 3 months, 1 year, 3M bundle, lifetime bundle)
- 6 Flexible Banner products (1 month, 3 months, 6 months, 1 year, 6M bundle, 1Y bundle)

SANDBOX TESTER ACCOUNT:
Email: [sandbox.tester@example.com]
Password: [provided separately via App Store Connect reply]

TESTING INSTRUCTIONS:
1. Sign out of current App Store account
2. Sign into App Store with provided sandbox account
3. Install or update app from TestFlight
4. Launch app and navigate to [purchase screen location]
5. All 18 products will be visible for testing
6. Complete a test purchase to verify functionality
7. Purchases in sandbox do not result in real charges

The app is ready for review. Please let us know if you need any additional information.

Thank you,
[Your Name]
ArtBeat Development Team
```

### Checklist - Before Resubmission
- [ ] All 18 IAP products visible in App Store Connect
- [ ] Each product has unique product ID
- [ ] Each product has unique display name and description
- [ ] Each product has a price tier assigned
- [ ] Sandbox access is enabled for each product
- [ ] Paid Apps Agreement is accepted
- [ ] Account holder information is complete and verified
- [ ] Sandbox tester account created
- [ ] Test device can see all 18 products in app
- [ ] Test purchases work for at least 3 different products
- [ ] Restore Purchases function works
- [ ] Documentation prepared for Apple review
- [ ] Sandbox account credentials ready to share with Apple
