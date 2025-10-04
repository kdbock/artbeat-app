# 🎯 Next Security Steps

## ✅ Completed Actions (October 3, 2025)

1. ✅ **Deleted Google Service Account Private Key**
   - Key ID: `6a65409fb78aa1178ecd79e4e07952b3e8fc8c99`
   - Deleted from Google Cloud Console

2. ✅ **Rotated Stripe Publishable Key**
   - Old key rolled and will expire in 8 days
   - Current active key: `pk_live_51QpJ6iAO5ulTKoALLtQFut6aQIyhLvrcUWRgA8RINvB6xwa37NeKymcV5lM96Yg6oOXvMQuwjPzP5LbE6I5ktHWG00Xk24gmn2`

---

## 🔴 HIGH PRIORITY - Complete This Week

### 1. Update Local Development Environment

Create your `.env.local` file:

```bash
cp .env.local.example .env.local
```

Edit `.env.local` and add your keys:

```bash
export ENVIRONMENT=development
export GOOGLE_MAPS_API_KEY=your_actual_key_here
export STRIPE_PUBLISHABLE_KEY=pk_live_51QpJ6iAO5ulTKoALLtQFut6aQIyhLvrcUWRgA8RINvB6xwa37NeKymcV5lM96Yg6oOXvMQuwjPzP5LbE6I5ktHWG00Xk24gmn2
```

### 2. Restrict Google Maps API Keys

For each of these keys, go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials):

| Key (last 4 chars) | Current Location | Action Required |
|-------------------|------------------|-----------------|
| `qHA` | iOS, Android, key.properties | Restrict to package/bundle ID |
| `6TA` | Firebase/Android | Restrict to package name |
| `kdA` | iOS/Web | Restrict to bundle ID/domain |
| `SH0` | Maps Diagnostic | Restrict or delete if unused |

**Steps for each key:**
1. Click on the key name
2. Under "Application restrictions", select:
   - For Android keys: "Android apps" → Add `com.wordnerd.artbeat`
   - For iOS keys: "iOS apps" → Add your bundle ID
   - For Web keys: "HTTP referrers" → Add your domains
3. Under "API restrictions", select "Restrict key"
4. Enable only: Maps SDK for Android, Maps SDK for iOS, Places API
5. Click "Save"

### 3. Update CI/CD Secrets

If you use GitHub Actions or other CI/CD:

1. Go to your repository Settings → Secrets and variables → Actions
2. Update/Add these secrets:
   - `STRIPE_PUBLISHABLE_KEY` = `pk_live_51QpJ6iAO5ulTKoALLtQFut6aQIyhLvrcUWRgA8RINvB6xwa37NeKymcV5lM96Yg6oOXvMQuwjPzP5lM96Yg6oOXvMQuwjPzP5LbE6I5ktHWG00Xk24gmn2`
   - `GOOGLE_MAPS_API_KEY` = (your restricted key)

---

## 🟡 MEDIUM PRIORITY - Complete This Month

### 4. Regenerate OAuth Client Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com) → APIs & Services → Credentials
2. Find OAuth 2.0 Client ID: `665020451634-sb8o1cgfji453vifsr3gqqqe1u2o5in4`
3. Delete it
4. Create new OAuth 2.0 Client ID
5. Download credentials
6. Store ONLY on backend server (never in client app or assets)

### 5. Audit Recent Activity

**Firebase Console Audit:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Check "Authentication" for unusual sign-ins
3. Check "Firestore" for unauthorized data access
4. Check "Storage" for unexpected uploads

**Stripe Dashboard Audit:**
1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Check recent transactions for anything suspicious
3. Review webhook activity
4. Check for any unusual API usage

### 6. Setup Git History Scanning (Optional but Recommended)

Enable GitHub secret scanning:
1. Go to your repository Settings → Code security and analysis
2. Enable "Secret scanning"
3. Enable "Push protection" to prevent future commits with secrets

---

## 🟢 ONGOING - Best Practices

### Daily
- [ ] Use `./scripts/build_secure.sh` for all builds
- [ ] Never commit sensitive files

### Weekly  
- [ ] Run `./scripts/security_verify.sh` to check for issues
- [ ] Review any new dependencies for vulnerabilities

### Monthly
- [ ] Review API key restrictions
- [ ] Check for unused/old API keys and delete them
- [ ] Review Firebase/Stripe activity logs

### Quarterly
- [ ] Rotate API keys as a best practice
- [ ] Full security audit with `security_verify.sh`
- [ ] Review team access permissions

---

## 📞 Quick Links

- [Google Cloud Console](https://console.cloud.google.com)
- [Firebase Console](https://console.firebase.google.com)
- [Stripe Dashboard](https://dashboard.stripe.com)
- [Security Configuration Guide](./SECURITY_CONFIGURATION.md)
- [Setup Guide](./SETUP_SECURE_CONFIG.md)

---

## ✨ Test Your Setup

After completing the above steps, test everything:

```bash
# 1. Verify no security issues
./scripts/security_verify.sh

# 2. Test build with new configuration
./scripts/build_secure.sh run

# 3. Verify app works correctly
# - Test Google Maps functionality
# - Test Stripe payment flow
# - Test Firebase authentication
```

---

**Last Updated:** October 3, 2025
**Status:** 🟢 Critical actions completed, high priority items in progress
