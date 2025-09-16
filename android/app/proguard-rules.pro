# Stripe SDK rules
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# Keep Stripe SDK classes
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.view.** { *; }
-keep class com.stripe.android.paymentsheet.** { *; }

# General rules for React Native
-keep class com.facebook.react.** { *; }
-keep class com.facebook.hermes.** { *; }

# Keep your application classes
-keep class com.wordnerd.artbeat.** { *; }

# Suppress warnings for unused ProGuard rules from dependencies
-dontwarn j$.util.**
-dontwarn j$.util.concurrent.**
