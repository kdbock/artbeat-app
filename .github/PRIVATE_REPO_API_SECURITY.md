# API Security in Private Repositories

This document outlines our approach to API key management in the ARTbeat application, which is maintained in a private repository.

## Current Approach

Since our repository is private and accessible only to authorized team members, we have implemented a hybrid security approach:

1. **Environment Variables**: We use a `.env` file to store API keys when available
2. **Fallback Mechanism**: If environment variables aren't available, we fallback to the original API keys
3. **Secure Access**: All API keys are accessed through the `AppConfig` and specific secure service classes

## Benefits of This Approach

1. **Repository Privacy**: Our private repository provides the first layer of security
2. **Development Convenience**: Developers can quickly start working without setting up environment variables
3. **Production Readiness**: The environment variable system is in place if we ever need to make the repository public
4. **Flexibility**: We can easily switch between development and production key management

## Best Practices

Even in a private repository, we recommend following these best practices:

1. **Limit Repository Access**: Only grant access to team members who need it
2. **Use Environment Variables**: When possible, use the `.env` file instead of relying on fallbacks
3. **Regularly Audit**: Periodically review who has access to the repository
4. **Be Prepared**: Keep the secure API key management system ready in case repository status changes

## Steps for Public Repository Migration

If this repository ever needs to be made public, follow these steps:

1. Regenerate all API keys in their respective consoles
2. Update the `.env` file with the new keys
3. Remove all API key fallbacks in the code
4. Run the `scripts/update_api_keys.sh` script to update platform-specific files
5. Test all functionality with the new keys

## API Key Restrictions

Consider implementing these restrictions on your API keys, even in a private repository:

1. **Firebase API Keys**: Restrict by application ID
2. **Google Maps API Keys**: Restrict by application, IP address, or HTTP referrer
3. **Stripe API Keys**: Use restricted API keys with only the necessary permissions

## Conclusion

Our current setup balances security and development convenience for a private repository. The system is designed to be easily adapted if our security requirements change.
