# Quick Guide: Add Android Secrets to GitHub

**Time Required:** 5 minutes  
**Status:** Ready to do RIGHT NOW ✅

---

## 🎯 What You're Doing

Adding 4 Android secrets to your GitHub repository so the CI/CD pipeline can sign your Android app releases.

---

## 📋 Step-by-Step Instructions

### Step 1: Open GitHub Secrets Page

1. Go to: https://github.com/kdbock/artbeat-app
2. Click **Settings** (top menu)
3. Click **Secrets and variables** → **Actions** (left sidebar)
4. You should see "Actions secrets and variables" page

---

### Step 2: Add Secret #1 - ANDROID_KEYSTORE_BASE64

1. Click **New repository secret** (green button)
2. **Name:** `ANDROID_KEYSTORE_BASE64`
3. **Value:** Copy the entire contents of this file:
   ```bash
   cat /Users/kristybock/secure-keys/artbeat/keystore-base64.txt
   ```
4. Run the command above in your terminal
5. Select ALL the output (should be 3,729 characters)
6. Copy and paste into the "Value" field
7. Click **Add secret**

**✅ Verification:** The secret should appear in the list with a green checkmark

---

### Step 3: Add Secret #2 - ANDROID_KEYSTORE_PASSWORD

1. Click **New repository secret**
2. **Name:** `ANDROID_KEYSTORE_PASSWORD`
3. **Value:** `passcode100328`
4. Click **Add secret**

---

### Step 4: Add Secret #3 - ANDROID_KEY_ALIAS

1. Click **New repository secret**
2. **Name:** `ANDROID_KEY_ALIAS`
3. **Value:** `artbeat-release`
4. Click **Add secret**

---

### Step 5: Add Secret #4 - ANDROID_KEY_PASSWORD

1. Click **New repository secret**
2. **Name:** `ANDROID_KEY_PASSWORD`
3. **Value:** `passcode100328`
4. Click **Add secret**

---

## ✅ Verification

After adding all 4 secrets, you should see them listed on the Actions secrets page:

- ✅ ANDROID_KEYSTORE_BASE64
- ✅ ANDROID_KEYSTORE_PASSWORD
- ✅ ANDROID_KEY_ALIAS
- ✅ ANDROID_KEY_PASSWORD

**Note:** You won't be able to view the secret values after adding them (GitHub hides them for security).

---

## 🎉 What's Next?

After adding these 4 secrets, you have 2 options:

### Option A: Continue with Firebase Setup (Recommended)

- Follow: `FIREBASE_STAGING_SETUP.md`
- Create Firebase staging project
- Add remaining Firebase secrets
- **Time:** ~35 minutes

### Option B: Test What You Have So Far

- Create a simple test pull request
- The PR checks will run (lint, tests, build)
- Android build will use your new keystore
- **Time:** ~10 minutes

---

## 🆘 Troubleshooting

### "I can't find the Settings tab"

- Make sure you're logged into GitHub
- Make sure you have admin access to the repository
- Try this direct link: https://github.com/kdbock/artbeat-app/settings/secrets/actions

### "The base64 string is too long to copy"

- Use the terminal command to copy: `cat ~/secure-keys/artbeat/keystore-base64.txt | pbcopy`
- This copies it to your clipboard automatically
- Then paste into GitHub

### "I made a mistake in a secret"

- You can delete and re-add secrets
- Click the secret name → Delete → Add new secret with correct value

---

## 📝 Quick Copy-Paste Reference

**For easy copying, here are all the values:**

```
Secret 1: ANDROID_KEYSTORE_BASE64
Command: cat /Users/kristybock/secure-keys/artbeat/keystore-base64.txt
(or use: cat ~/secure-keys/artbeat/keystore-base64.txt | pbcopy)

Secret 2: ANDROID_KEYSTORE_PASSWORD
Value: passcode100328

Secret 3: ANDROID_KEY_ALIAS
Value: artbeat-release

Secret 4: ANDROID_KEY_PASSWORD
Value: passcode100328
```

---

## 🔐 Security Note

These secrets are encrypted by GitHub and only accessible to GitHub Actions workflows. They won't be visible in logs or to other users.

---

**Ready?** Let's add those secrets! 🚀

After you're done, come back and we'll continue with the Firebase setup.
