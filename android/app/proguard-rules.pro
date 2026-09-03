# Flutter / Dart
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# WorkManager + Room (AdMob / Firebase / notifications)
# AGP 9 R8 full mode strips no-arg constructors used via reflection.
# { *; } does NOT keep constructors — <init> must be kept explicitly.
# Crash: Failed to create an instance of androidx.work.impl.WorkDatabase
-keep class androidx.startup.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.work.** { <init>(...); }
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keep class * extends androidx.room.RoomDatabase {
    <init>();
    public ** createInvalidationTracker();
    public void clearAllTables();
}
-dontwarn androidx.work.impl.**
-dontwarn androidx.room.**

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.**

# Play Core (Flutter deferred components / split)
-dontwarn com.google.android.play.core.**

# Hive
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
