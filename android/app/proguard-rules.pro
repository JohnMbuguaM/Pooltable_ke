# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# SQLite (sqflite)
-keep class com.tekartik.sqflite.** { *; }

# Keep model classes used via reflection / serialization
-keep class com.pooltableke.pooltable_ke.** { *; }
