# App Store Review Compliance Guide

## User-Generated Content Moderation

### Where to Find Report/Block Features

Users can report or block other users through the following locations:

1. **Community Feed Posts**
   - Long-press or tap the three-dot menu on any community post
   - Select "Report" to report inappropriate content
   - Select "Block user" to block the content creator

2. **User Profiles**
   - Tap the three-dot menu icon on any artist or user profile
   - Select "Report" to report a user
   - Select "Block user" to prevent seeing content from that user

3. **Comments & Interactions**
   - Each comment has a report option in the context menu
   - Users can block commenters directly from the comment

### Report Categories

Users can report content for the following reasons:
- Harassment or bullying
- Hate speech or discrimination
- Inappropriate content
- Spam or scam
- Copyright infringement
- Misinformation
- Other

### Block Management

Users can manage their blocked users list at:
- **Settings** → **Privacy Settings** → **Blocked Users**

All reports are reviewed by our moderation team and action is taken according to our Terms of Service.

---

## In-App Purchase Features

### Where to Find In-App Purchase

Users can access In-App Purchase options in the following locations:

#### 1. **Subscriptions**
   - **Settings** → **Account** → **Subscription Plans**
   - Or navigate to **Profile** → **Upgrade to Premium**
   - Available subscription tiers:
     - **Basic**: Free tier (default)
     - **Creator**: $9.99/month
     - **Pro**: $19.99/month
     - **Enterprise**: Contact us for pricing

#### 2. **Gifts & Support**
   - **Community** → **Send Gifts**
   - Send virtual gifts to artists and creators
   - Gift packages: $0.99, $2.99, $4.99, $9.99

#### 3. **Artwork Promotion & Ads**
   - **Artist Dashboard** → **Promote Artwork**
   - **Ads Management** → **Create Ad Campaign**
   - Flexible ad packages from $4.99 to $99.99
   - Pay-per-impression model

#### 4. **Demo/Testing Account**
   - The demo account has full access to:
     - View all subscription tiers in the comparison screen
     - See all gift options
     - Access all promotion packages
   - Users can preview what each subscription tier offers without purchasing

### Testing In-App Purchase

To test In-App Purchase functionality:

1. Use a test account in TestFlight (for testers) or Sandbox (for developers)
2. Navigate to **Community** → **Gifts** to see available gift packages
3. Tap "Send" on any gift package to initiate a purchase
4. In Sandbox mode, you'll see a preview of the payment
5. Complete the transaction using your test payment method

### Subscription Plans Overview

| Tier | Price | Benefits |
|------|-------|----------|
| Basic | Free | View art, browse community, discover art walks |
| Creator | $9.99/month | Post artwork, create art walks, send gifts |
| Pro | $19.99/month | All Creator benefits + Ad priority, analytics |
| Enterprise | Custom | All Pro benefits + Custom branding, API access |

### Purchase History

Users can view their purchase history and manage active subscriptions at:
- **Settings** → **Account** → **Purchase History**
- Manage renewals and cancellations in App Store settings (handled by Apple)

---

## Privacy & Safety

### Data Protection
All user data, including reports and block lists, are:
- Encrypted in transit (TLS 1.2+)
- Encrypted at rest in Firestore
- Compliant with GDPR, CCPA, and COPPA

### Blocked Users
- Blocked users cannot view your profile
- Blocked users cannot message you
- Blocked users cannot interact with your content
- You can unblock users anytime

### Report Privacy
- Reports are anonymous to the reported user
- Only moderators and admins can see report details
- Reports help keep the community safe

---

## For App Review Testers

### Demo Account Credentials
- Email: `demo@localartbeat.app`
- Password: `DemoPassword123!`

### Quick Testing Steps

1. **Test Sign In with Apple**
   - Launch the app
   - Tap "Sign in with Apple"
   - Complete Apple's authentication flow
   - Verify successful login

2. **Find Report/Block Features**
   - Go to Community tab
   - Browse community feed
   - Tap three-dot menu on any post
   - Select "Report" or "Block user"

3. **Find In-App Purchase**
   - Go to Community tab
   - Tap "Send Gifts" option
   - View available gift packages
   - (In Sandbox) Proceed through purchase flow

4. **Test With Demo Account**
   - After login with Apple, you can immediately:
     - View subscription tiers
     - Access gift sending
     - Browse promotion packages
   - No additional setup required

---

## Contact

For questions or support:
- Email: support@localartbeat.app
- In-app support: Settings → Help & Support
