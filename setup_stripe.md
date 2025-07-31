# Setting up Stripe for ARTbeat

## Step 1: Get your Stripe Secret Key

1. Go to your Stripe Dashboard: https://dashboard.stripe.com/
2. Navigate to "Developers" > "API keys"
3. Copy your **Secret key** (starts with `sk_live_` for production or `sk_test_` for testing)

## Step 2: Configure Firebase Functions

Run this command to set your Stripe secret key in Firebase Functions:

```bash
cd /Users/kristybock/artbeat
firebase functions:config:set stripe.secret_key="your_secret_key_here"
```

Replace `your_secret_key_here` with your actual Stripe secret key.

## Step 3: Deploy the Functions

After setting the configuration, deploy the functions:

```bash
cd /Users/kristybock/artbeat/functions
npm run deploy
```

## Step 4: Update Client-side Stripe Configuration

You'll also need to configure the Stripe publishable key in your Flutter app. Look for where Stripe is initialized in your Flutter code and make sure it uses your publishable key.

## For Testing (Recommended First)

If you want to test first, use your test keys instead:

- Test Secret Key: `sk_test_...`
- Test Publishable Key: `pk_test_...`

This way you can test payments without real money being involved.

## Current Status

The error you're seeing is because the Firebase Functions don't have access to the Stripe secret key. Once you complete steps 1-3 above, the customer creation should work properly.
