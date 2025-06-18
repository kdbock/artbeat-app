# Security Policy

## Configuration Management

### Environment Variables
All sensitive configuration values must be stored in environment variables using a `.env` file. Never commit the `.env` file to version control.

1. Copy `.env.example` to create your `.env` file:
```bash
cp .env.example .env
```

2. Add your configuration values to the `.env` file

3. The app will automatically load these values through the `ConfigService`

### API Keys and Secrets

#### Firebase Configuration
- Never commit `google-services.json` or `GoogleService-Info.plist`
- Store Firebase configuration in environment variables
- Use `ConfigService` to access Firebase configuration values

#### Google Maps API Keys
- Store Google Maps API keys in environment variables
- Use appropriate key restrictions in Google Cloud Console
- For Android: Restrict by package name and SHA-1 certificate fingerprint
- For iOS: Restrict by bundle identifier

#### Stripe API Keys
- Only use restricted API keys with minimum required permissions
- Store API keys in environment variables
- Never log or expose API keys in client-side code

### Security Best Practices

1. **API Key Rotation**
   - Rotate API keys every 90 days
   - Immediately rotate any potentially exposed keys
   - Update `.env` files after key rotation

2. **Access Control**
   - Use Firebase Authentication for user management
   - Implement proper Firestore security rules
   - Enable Firebase App Check in production

3. **Secure Communication**
   - Use HTTPS for all API communications
   - Implement certificate pinning where appropriate
   - Enable App Check token verification

4. **Data Security**
   - Encrypt sensitive data at rest
   - Use secure key storage for credentials
   - Implement proper data backup procedures

5. **Monitoring and Alerts**
   - Monitor API key usage for suspicious activity
   - Set up alerts for unusual patterns
   - Regularly review security logs

## Reporting Security Issues

If you discover a security vulnerability, please:

1. Do NOT open a public GitHub issue
2. Email security@artbeat.com with details
3. Allow 48 hours for initial response
4. Do not disclose the issue publicly until it has been addressed

## Compliance Requirements

1. Code Review
   - All security-related changes require review
   - Use static analysis tools for security checks
   - Regular security audits of dependencies

2. Testing
   - Include security tests in CI/CD pipeline
   - Regular penetration testing
   - Vulnerability scanning of dependencies

3. Documentation
   - Keep security documentation up to date
   - Document all security-related configurations
   - Maintain incident response procedures
