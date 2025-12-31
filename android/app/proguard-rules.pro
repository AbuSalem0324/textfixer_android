# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# HTTP client
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**

# Device info plus
-keep class io.flutter.plugins.deviceinfoplus.** { *; }

# Shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Google Fonts
-keep class com.google.android.gms.fonts.** { *; }
-keep class androidx.core.provider.** { *; }

# Keep application class
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Play Core missing classes - add dummy rules
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep all mipmap resources (app icons)
-keep class **.R$mipmap { *; }
-keepclassmembers class **.R$mipmap { *; }

# Keep all drawable resources
-keep class **.R$drawable { *; }
-keepclassmembers class **.R$drawable { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Remove debug logging
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}