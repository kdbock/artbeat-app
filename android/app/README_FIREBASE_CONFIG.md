# Firebase Configuration for CI/CD

## Overview

This directory contains Firebase configuration files that are required for building the Android app.

## Files

### `google-services.json` (gitignored)

The actual Firebase configuration file containing your project's credentials. This file is:

- **Required** for local development and production builds
- **Gitignored** to protect sensitive Firebase credentials
- **Not committed** to version control

### `google-services.json.template`

A template version of the configuration file used for CI/CD builds. This file:

- Contains placeholder values that allow the build to complete
- Is **safe to commit** to version control
- Is automatically used during GitHub Actions builds

## Setup

### For Local Development

1. Download your actual `google-services.json` from the Firebase Console:
   - Go to Project Settings
   - Select your Android app
   - Download the `google-services.json` file
2. Place it in `android/app/google-services.json`
3. The file will be automatically ignored by git

### For CI/CD (GitHub Actions)

The workflow automatically creates `google-services.json` from the template during Android builds.
No manual setup required.

### For Production Builds

For production releases, you should use GitHub Secrets:

1. Add your production `google-services.json` content as a GitHub secret:

   - Go to Repository Settings → Secrets and variables → Actions
   - Create a new secret named `GOOGLE_SERVICES_JSON`
   - Paste the entire content of your production `google-services.json`

2. Update the workflow to use the secret for release builds:
   ```yaml
   - name: Create google-services.json for production
     if: matrix.platform == 'android' && github.ref == 'refs/heads/main'
     run: |
       echo '${{ secrets.GOOGLE_SERVICES_JSON }}' > android/app/google-services.json
   ```

## Security Notes

- ✅ **NEVER** commit the actual `google-services.json` file
- ✅ **ALWAYS** use the template for CI builds
- ✅ **USE** GitHub Secrets for production deployments
- ⚠️ The template contains dummy values and won't work for actual Firebase functionality
