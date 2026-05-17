# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Supabase / OkHttp / Kotlin serialization
-keep class io.github.jan.supabase.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Keep model classes used by JSON parsing
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
