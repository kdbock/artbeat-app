# Security Changes - June 15, 2025

## 🚨 Critical Security Updates

1. **Environment Variables**
   - All sensitive keys have been moved to `.env`
   - Copy `.env.example` to `.env` and fill in your values
   - Never commit `.env` files

2. **Service Account**
   - The Google Cloud service account key has been removed from git
   - Contact the tech lead for a new key
   - Store the key securely outside the project directory

3. **New ConfigService**
   - Use `ConfigService.instance.get('KEY_NAME')` to access configuration
   - All Firebase/Google configurations must use this service
   - See `packages/artbeat_core/lib/src/services/config_service.dart` for usage

## Required Actions

1. Delete any local copies of `service_account.json`
2. Run `flutter pub get` in the core module
3. Create your `.env` file from `.env.example`
4. Update your environment with secure keys (contact tech lead)

## Security Best Practices

1. Never commit sensitive keys or credentials
2. Use environment variables for all sensitive data
3. Rotate keys regularly
4. Report any security concerns immediately

Contact the security team for any questions or concerns.
