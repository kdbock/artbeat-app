# Crash Fix Quick Reference

## 🚨 Critical Initialization Order (main.dart)

```
1. Firebase.initializeApp() ← MUST BE FIRST
2. AuthSafetyService.initialize()
3. StripeSafetyService.initialize()
4. InAppPurchaseSetup.initialize() (with retry)
5. Other services...
```

## 🔒 Using the Safety Services

### Stripe Payment (Payment Flow)

**Before** ❌:

```dart
await Stripe.instance.presentPaymentSheet();
```

**After** ✅:

```dart
if (!StripeSafetyService.isReadyForPayments) {
  showError('Payment service not ready');
  return;
}

final result = await StripeSafetyService.safePresentPaymentSheet(
  presentFunction: () => Stripe.instance.presentPaymentSheet(),
  intentData: paymentIntent,
  customerData: customer,
);

if (result == PaymentSheetResult.completed) {
  // Success
}
```

### Google Sign-In (Auth Flow)

**Before** ❌:

```dart
final account = await googleSignIn.signIn();
```

**After** ✅:

```dart
final account = await AuthSafetyService.safeGoogleSignIn();
if (account != null) {
  // Proceed with sign in
} else {
  showError('Sign-in failed');
}
```

### In-App Purchases (IAP Setup)

**Before** ❌:

```dart
await InAppPurchaseSetup().initialize();
```

**After** ✅:

```dart
final crashRecovery = CrashRecoveryService();
final success = await crashRecovery.executeInitializationWithPanicRecovery(
  initialization: () async {
    await InAppPurchaseSetup().initialize();
    return true;
  },
  initName: 'InAppPurchaseSetup',
);

if (!success) {
  // IAP will be unavailable but app won't crash
}
```

---

## 📊 Status Checks

### Check Stripe Status

```dart
print(StripeSafetyService.isInitialized);      // true/false
print(StripeSafetyService.isReadyForPayments); // true/false
print(StripeSafetyService.getStatusDetails()); // Map with all status
```

### Check Auth Status

```dart
print(AuthSafetyService.isInitialized);       // true/false
print(AuthSafetyService.isReady);             // true/false
print(AuthSafetyService.isGoogleSignedIn);    // true/false
print(AuthSafetyService.getCurrentUser());    // GoogleSignInAccount?
```

### Check Crash Recovery Status

```dart
final stats = CrashRecoveryService().getFailureStats('MyOperation');
print(stats); // {'failureCount': 2, 'shouldRetry': true, ...}
```

---

## 🛡️ Error Handling Patterns

### Pattern 1: Try-Catch with Fallback

```dart
try {
  await StripeSafetyService.initialize(publishableKey: key);
} catch (e) {
  AppLogger.warning('Stripe not available: $e');
  // Continue - payment features will be unavailable
}
```

### Pattern 2: Conditional Feature Access

```dart
if (StripeSafetyService.isReadyForPayments) {
  // Show payment button
} else {
  // Hide payment button or show "Coming Soon"
}
```

### Pattern 3: Graceful Degradation

```dart
final account = await AuthSafetyService.safeGoogleSignIn();
if (account == null) {
  // Fall back to email/password auth
  showEmailPasswordForm();
} else {
  // Use Google sign-in
  processGoogleSignIn(account);
}
```

---

## ⚠️ Common Issues and Fixes

### Issue: "Stripe Safety Service not initialized"

**Fix**: Ensure `StripeSafetyService.initialize()` is called in main.dart

### Issue: "Auth Safety Service not initialized"

**Fix**: Ensure `AuthSafetyService.initialize()` is called in main.dart

### Issue: "Payment intent validation failed"

**Fix**: Check that `client_secret` is present in payment intent data

### Issue: "Google Sign-In returned null"

**Fix**: This is normal if user cancelled. Handle null gracefully.

### Issue: "Operation timed out"

**Fix**: User may have poor network. Show retry button.

---

## 🔄 Recovery Retry Logic

```dart
// Automatic retries with exponential backoff
// Attempt 1: Wait 100ms
// Attempt 2: Wait 200ms
// Attempt 3: Wait 400ms
// Max 3 attempts total
```

---

## 📱 Testing Commands

```bash
# Test with logging enabled
flutter run -v | grep "🔒\|✅\|❌"

# Test crash recovery
# Manually kill app during initialization
# App should recover and not crash on restart

# Test without payment key
# Remove STRIPE_PUBLISHABLE_KEY from .env
# App should start normally (payment features unavailable)
```

---

## 🎯 Key Takeaways

1. **Always initialize in order**: Firebase → Auth → Stripe → IAP
2. **Check status before use**: Use `isReady` or `isInitialized` properties
3. **Never skip error handling**: Wrap in try-catch or check status
4. **Graceful degradation**: Disable features instead of crashing
5. **Use safety services**: Don't call payment/auth directly - use wrapped versions

---

## 📞 Quick Help

| Issue        | Solution                         | File                        |
| ------------ | -------------------------------- | --------------------------- |
| Stripe crash | Use `StripeSafetyService`        | stripe_safety_service.dart  |
| Auth crash   | Use `AuthSafetyService`          | auth_safety_service.dart    |
| Init crash   | Use `CrashRecoveryService`       | crash_recovery_service.dart |
| All failing  | Check `main.dart` initialization | main.dart                   |

---

## 🚀 Before Calling External Payment APIs

**Checklist**:

- [ ] Service is initialized
- [ ] Status shows ready
- [ ] All required data validated
- [ ] Error handling in place
- [ ] User feedback available
