# 🔑 Update Stripe Production Key

## ⚠️ Important: Real Stripe Key Available

I noticed you have the **real Stripe production publishable key**. Let's update it!

---

## 🔐 Current Status

### What You Have Now

- **Secret Name:** `PRODUCTION_STRIPE_PUBLISHABLE_KEY`
- **Current Value:** `pk_live_placeholder` (placeholder)
- **Real Value:** `pk_live_51QpJ6iAO5ulTKoALD0MCyfwOCP2ivyVgKNK457uvrjJ0N9uj9Y7uSAtWfYq7nyuFZFqMjF4BHaDOYuMpwxd0PdbK00Ooktqk6z`

---

## ✅ How to Update

### Step 1: Copy the Real Key

```bash
echo "pk_live_51QpJ6iAO5ulTKoALD0MCyfwOCP2ivyVgKNK457uvrjJ0N9uj9Y7uSAtWfYq7nyuFZFqMjF4BHaDOYuMpwxd0PdbK00Ooktqk6z" | pbcopy
```

### Step 2: Update GitHub Secret

1. Go to: https://github.com/kdbock/artbeat-app/settings/secrets/actions
2. Find `PRODUCTION_STRIPE_PUBLISHABLE_KEY`
3. Click **"Update"**
4. Paste the real key
5. Click **"Update secret"**

---

## 🚨 CRITICAL: Stripe Secret Key

### ⚠️ DO NOT Add This to GitHub Secrets!

You also have a **Stripe secret key**:

```
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
```

**This is DANGEROUS if exposed!**

### What is a Secret Key?

- Starts with `sk_live_` (secret key) or `sk_test_` (test secret key)
- Can charge customers
- Can access all Stripe data
- Should NEVER be in client-side code
- Should NEVER be in GitHub secrets (for mobile apps)

### Where Should It Go?

**Option 1: Firebase Functions (Recommended)**

Store it in Firebase Functions configuration:

```bash
# Set the secret in Firebase Functions
firebase functions:secrets:set STRIPE_SECRET_KEY

# When prompted, paste:
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
```

Then use it in your functions:

```typescript
// functions/src/stripe.ts
import { defineSecret } from "firebase-functions/params";

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

export const createPaymentIntent = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    const stripe = new Stripe(stripeSecretKey.value(), {
      apiVersion: "2023-10-16",
    });

    // Use stripe to create payment intent
  }
);
```

**Option 2: Google Secret Manager**

```bash
# Store in Google Secret Manager
echo -n "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" | \
  gcloud secrets create stripe-secret-key --data-file=-
```

---

## 📋 Stripe Keys Summary

### Publishable Keys (Safe for Client)

✅ Can be in mobile app code
✅ Can be in GitHub secrets
✅ Used to initialize Stripe SDK

- **Test:** `pk_test_placeholder` (you need to get the real one)
- **Production:** `pk_live_51QpJ6iAO5ulTKoALD0MCyfwOCP2ivyVgKNK457uvrjJ0N9uj9Y7uSAtWfYq7nyuFZFqMjF4BHaDOYuMpwxd0PdbK00Ooktqk6z`

### Secret Keys (NEVER in Client)

❌ NEVER in mobile app code
❌ NEVER in GitHub secrets (for mobile apps)
✅ Only in backend (Firebase Functions, server)

- **Test:** `sk_test_...` (you need to get this from Stripe)
- **Production:** `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`

---

## 🎯 Action Items

### Immediate

1. ✅ Update `PRODUCTION_STRIPE_PUBLISHABLE_KEY` with real key
2. ✅ Store Stripe secret key in Firebase Functions
3. ⚠️ Delete the secret key from any notes/files

### Later

1. Get real test publishable key from Stripe
2. Update `STAGING_STRIPE_PUBLISHABLE_KEY`
3. Get test secret key and store in Firebase Functions

---

## 🔒 Security Best Practices

### DO ✅

- Use publishable keys in mobile apps
- Store secret keys in Firebase Functions
- Use environment-specific keys (test vs production)
- Rotate keys if compromised

### DON'T ❌

- Put secret keys in mobile app code
- Commit secret keys to git
- Share secret keys in chat/email
- Use production keys for testing

---

## 🆘 If Secret Key Was Exposed

If you accidentally exposed the secret key:

1. **Immediately revoke it in Stripe Dashboard**

   ```bash
   open https://dashboard.stripe.com/apikeys
   ```

2. **Generate a new secret key**

3. **Update Firebase Functions with new key**

   ```bash
   firebase functions:secrets:set STRIPE_SECRET_KEY
   ```

4. **Review Stripe logs for suspicious activity**

---

## ✅ Verification

After updating:

1. **Check GitHub Secret**

   - Go to: https://github.com/kdbock/artbeat-app/settings/secrets/actions
   - Verify `PRODUCTION_STRIPE_PUBLISHABLE_KEY` shows "Updated X minutes ago"

2. **Check Firebase Functions**

   ```bash
   firebase functions:secrets:access STRIPE_SECRET_KEY
   ```

3. **Test in App**
   - Build production app
   - Try to initialize Stripe
   - Should work with real key

---

## 📚 Learn More

- [Stripe API Keys](https://stripe.com/docs/keys)
- [Firebase Functions Secrets](https://firebase.google.com/docs/functions/config-env#secret-manager)
- [Stripe Security Best Practices](https://stripe.com/docs/security/guide)

---

## 🎉 Summary

**Update the publishable key:**

```bash
# Copy to clipboard
echo "pk_live_51QpJ6iAO5ulTKoALD0MCyfwOCP2ivyVgKNK457uvrjJ0N9uj9Y7uSAtWfYq7nyuFZFqMjF4BHaDOYuMpwxd0PdbK00Ooktqk6z" | pbcopy

# Then update in GitHub
open https://github.com/kdbock/artbeat-app/settings/secrets/actions
```

**Store the secret key:**

```bash
firebase functions:secrets:set STRIPE_SECRET_KEY
# Paste: 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
```

Done! 🎉
