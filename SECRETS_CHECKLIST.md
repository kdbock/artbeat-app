# GitHub Secrets Checklist

Track your progress adding secrets to GitHub.

**Repository:** https://github.com/kdbock/artbeat-app/settings/secrets/actions

---

## ✅ Android Secrets (Ready NOW)

- [ ] **ANDROID_KEYSTORE_BASE64**
  - Value: Run `cat ~/secure-keys/artbeat/keystore-base64.txt | pbcopy` (copies to clipboard)
  - Size: 3,729 characters
- [ ] **ANDROID_KEYSTORE_PASSWORD**
  - Value: `passcode100328`
- [ ] **ANDROID_KEY_ALIAS**
  - Value: `artbeat-release`
- [ ] **ANDROID_KEY_PASSWORD**
  - Value: `passcode100328`

---

## ⏸️ Firebase Secrets (After Creating Staging Project)

- [ ] **FIREBASE_TOKEN**
  - Command: `firebase login:ci`
  - Copy the token from terminal output
- [ ] **FIREBASE_SERVICE_ACCOUNT**
  - Firebase Console → Project Settings → Service Accounts → Generate new private key
  - Copy entire JSON file contents
- [ ] **FIREBASE_ANDROID_APP_ID_STAGING**
  - Firebase Console → Staging Project → Project Settings → Android App → App ID
  - Format: `1:123456789:android:abc123...`
- [ ] **FIREBASE_IOS_APP_ID_STAGING** (Optional)
  - Firebase Console → Staging Project → Project Settings → iOS App → App ID
  - Format: `1:123456789:ios:abc123...`

---

## ⏸️ Environment Variables (After Filling in API Keys)

- [ ] **ENV_STAGING**
  - Fill in `.env.staging` with actual API keys first
  - Then: `cat .env.staging | pbcopy`
- [ ] **ENV_PRODUCTION**
  - Create `.env.production` from `.env.production.example`
  - Fill in actual API keys
  - Then: `cat .env.production | pbcopy`

---

## 🎯 Minimum to Test Pipeline

You need at least these **7 secrets** to test the basic CI/CD pipeline:

1. ✅ ANDROID_KEYSTORE_BASE64 (ready now)
2. ✅ ANDROID_KEYSTORE_PASSWORD (ready now)
3. ✅ ANDROID_KEY_ALIAS (ready now)
4. ✅ ANDROID_KEY_PASSWORD (ready now)
5. ⏸️ FIREBASE_TOKEN (after Firebase login)
6. ⏸️ ENV_STAGING (after filling in API keys)
7. ⏸️ ENV_PRODUCTION (after filling in API keys)

---

## 📊 Progress Tracker

**Secrets Added:** 0 / 7 minimum (0%)

Update this as you add secrets:

- After adding Android secrets: 4 / 7 (57%)
- After adding Firebase token: 5 / 7 (71%)
- After adding environment vars: 7 / 7 (100%) ✅

---

## 🚀 Quick Commands

### Copy keystore to clipboard

```bash
cat ~/secure-keys/artbeat/keystore-base64.txt | pbcopy
```

### Get Firebase token

```bash
firebase login:ci
```

### Copy staging env to clipboard

```bash
cat .env.staging | pbcopy
```

### Copy production env to clipboard

```bash
cat .env.production | pbcopy
```

---

## ✅ After Adding All Secrets

Test the pipeline:

```bash
# Create test branch
git checkout -b test/ci-pipeline

# Make a small change
echo "# CI/CD Test" >> README.md

# Commit and push
git add .
git commit -m "test: verify CI/CD pipeline"
git push origin test/ci-pipeline
```

Then create a pull request on GitHub and watch the checks run!

---

**Last Updated:** October 13, 2025
