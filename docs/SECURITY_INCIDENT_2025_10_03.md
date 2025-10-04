# 🔐 URGENT: Security Action Required

## ⚠️ Exposed Credentials Found

During a security audit, the following credentials were found hardcoded in the source code and have been **removed**:

### 1. Google Service Account Private Key
- **Location**: `packages/artbeat_core/lib/src/firebase/secure_firebase_config.dart`
- **Risk**: HIGH - Full service account access
- **Action Required**: ✅ **IMMEDIATELY REVOKE AND REGENERATE**

**Steps to revoke:**
1. Go to Google Cloud Console: https://console.cloud.google.com
2. Navigate to: IAM & Admin > Service Accounts
3. Find service account: `artbeat-play-verification@wordnerd-artbeat.iam.gserviceaccount.com`
4. Delete the key with ID: `6a65409fb78aa1178ecd79e4e07952b3e8fc8c99`
5. Generate a new key (if still needed)
6. Store new key ONLY on backend servers (Cloud Functions), NEVER in client app

### 2. Stripe Live Publishable Key
- **Location**: `packages/artbeat_core/lib/src/utils/env_loader.dart`
- **Risk**: MEDIUM - Could be abused, but limited without secret key
- **Key**: `pk_live_51QpJ6iAO5ulTKoALLtQFut6aQIyhLvrcUWRgA8RINvB6xwa37NeKymcV5lM96Yg6oOXvMQuwjPzP5LbE6I5ktHWG00Xk24gmn2`
- **Action Required**: ✅ **ROTATE IMMEDIATELY**

**Steps to rotate:**
1. Go to Stripe Dashboard: https://dashboard.stripe.com/apikeys
2. Roll the exposed publishable key
3. Update in CI/CD secrets and `.env.local`
4. Deploy new app version with new key

### 3. Google Maps API Keys
Multiple Google Maps API keys found in source code:
- `AIzaSyBvmSCvenoo9u-eXNzKm_oDJJJjC0MbqHA` (in multiple files)
- `AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA` (Firebase/Android)
- `AIzaSyAXFpdz_5cJ8m4ZDgBb7kVx7PHxinwEkdA` (iOS/Web)
- `AIzaSyDzH_pJ_I2U_rkC4OBKVasjjJMus3LtSH0` (Maps Diagnostic)

**Risk**: MEDIUM - Can incur charges if abused
**Action Required**: ✅ **RESTRICT IMMEDIATELY**

**Steps to restrict:**
1. Go to Google Cloud Console: https://console.cloud.google.com/apis/credentials
2. For each key, click "Edit"
3. Set Application restrictions:
   - Android: Restrict to package name `com.wordnerd.artbeat`
   - iOS: Restrict to bundle ID (your iOS bundle ID)
   - Web: Restrict to your domain(s)
4. Set API restrictions: Enable only required APIs
5. Set quotas to reasonable limits

### 4. OAuth Client Secret
- **Location**: `assets/client_secret_*.json` (removed)
- **Risk**: MEDIUM
- **Action Required**: ✅ **REVOKE AND REGENERATE**

**Steps:**
1. Go to Google Cloud Console > APIs & Services > Credentials
2. Find OAuth 2.0 Client ID: `665020451634-sb8o1cgfji453vifsr3gqqqe1u2o5in4`
3. Delete and create new credentials
4. Download new `client_secret.json`
5. Store securely (backend only, never in assets)

## ✅ Actions Taken

1. ✅ Removed all hardcoded secrets from source code
2. ✅ Untracked `google-services.json` from git
3. ✅ Deleted OAuth client secret from assets
4. ✅ Implemented secure configuration system using `--dart-define`
5. ✅ Updated `.gitignore` to prevent future exposure
6. ✅ Created documentation and build scripts

## 🚨 Immediate Action Checklist

- [ ] **REVOKE** exposed Google service account key
- [ ] **ROTATE** Stripe publishable key
- [ ] **RESTRICT** all Google Maps API keys
- [ ] **REGENERATE** OAuth client credentials
- [ ] **AUDIT** Firebase Console for unauthorized access
- [ ] **CHECK** Stripe Dashboard for suspicious activity
- [ ] **REVIEW** git history for other exposed secrets
- [ ] **NOTIFY** team members about security incident
- [ ] **DOCUMENT** incident in security log

## 🔄 Key Rotation Procedure

After revoking/rotating keys:

1. Update all keys in your local `.env.local` file
2. Update keys in CI/CD secrets (GitHub Actions, etc.)
3. Rebuild and deploy new app version:
   ```bash
   ./scripts/build_secure.sh build-appbundle
   ```
4. Wait for users to update to new version
5. Monitor for any issues
6. After 90% adoption, fully revoke old keys

## 📋 Git History Cleanup (If Needed)

If you want to remove these secrets from git history:

```bash
# CAUTION: This rewrites history and requires force push
# Coordinate with your team before running this!

# Install git-filter-repo (one time)
brew install git-filter-repo

# Backup your repo first
cd /Users/kristybock/artbeat
git clone . ../artbeat-backup

# Remove sensitive file from history
git filter-repo --path packages/artbeat_core/lib/src/firebase/secure_firebase_config.dart --invert-paths

# Force push (team coordination required!)
# git push origin --force --all
```

**WARNING**: Only do this if you understand the implications and have coordinated with your team!

## 🛡️ Prevention Measures

To prevent this from happening again:

1. ✅ Use the new `AppConfig` class for all configuration
2. ✅ Use `scripts/build_secure.sh` for all builds
3. ✅ Never hardcode secrets in source files
4. ✅ Review `.gitignore` before committing new files
5. ✅ Set up pre-commit hooks to scan for secrets
6. ✅ Enable GitHub secret scanning (if not already enabled)
7. ✅ Regular security audits (quarterly)

## 📞 Resources

- [Security Configuration Guide](./SECURITY_CONFIGURATION.md)
- Google Cloud Console: https://console.cloud.google.com
- Firebase Console: https://console.firebase.google.com
- Stripe Dashboard: https://dashboard.stripe.com

---

**Created**: October 3, 2025
**Priority**: 🚨 CRITICAL - Action required within 24 hours
**Status**: 🟡 Secrets removed from code, keys need rotation
