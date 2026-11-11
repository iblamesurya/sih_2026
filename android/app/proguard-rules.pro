# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep attributes
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod

# Supabase / HTTP / OkHttp / Coroutines
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Android Architecture Components
-keep class androidx.lifecycle.** { *; }
-keep class androidx.window.** { *; }

# Google Play Core Deferred Components
-dontwarn com.google.android.play.core.**

# Flutter Plugins (Geolocator, Image Picker, SharedPreferences)
-keep class com.baseflow.geolocator.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Crypto & Security
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# ==============================================================================
# Counter-REA & AI Agent Anti-Decompilation Locks (BLA Defense)
# ==============================================================================
# Repackage internal security and domain logic to flatten hierarchy
-repackageclasses ''
-allowaccessmodification

# Strip debug metadata and source file names to blind automated LLM AST builders
-renamesourcefileattribute 'PrawnGuardShield'

# Anti-reflection locking: Obfuscate and lock dynamic method invocation
-keepclassmembernames class * {
    java.lang.Class class$(java.lang.String);
    java.lang.Class class$(java.lang.String, boolean);
}

# Block dynamic reflection inspection of security providers
-dontnote **
-dontwarn **

# Strip verbose and debug logging in release bytecode to prevent recon
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
}
