#############################################
# Stripe SDK and flutter_stripe integration
#############################################

# Keep all Stripe SDK classes
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Keep Push Provisioning related classes
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# Keep networking classes including EphemeralKeyProvider
-keep class com.stripe.android.networking.** { *; }
-dontwarn com.stripe.android.networking.**

# flutter_stripe bridge
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**

# Kotlin
-dontwarn kotlin.**

# AndroidX and Google Play
-dontwarn androidx.**
-dontwarn com.google.android.gms.**
