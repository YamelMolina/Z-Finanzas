# Reglas para evitar que Android borre el código de Supabase en el APK final
-keep class io.supabase.** { *; }
-keep class com.google.gson.** { *; }
-keep class org.json.** { *; }
-dontwarn io.supabase.**

# Reglas para mantener los plugins de Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }