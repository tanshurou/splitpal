# Keep Stripe core classes (safe)
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**

# Keep Firebase + Flutter core
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }

# Optional: suppress any other class not found warnings
-dontwarn androidx.lifecycle.**
