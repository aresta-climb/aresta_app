# Regras do ProGuard / R8 para o Aresta App

# 1. Manter atributos essenciais para stacktraces e annotations no Crashlytics
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,SourceFile,LineNumberTable

# 2. Flutter Engine e Embeddings
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# 3. AndroidX WorkManager e plugin Flutter Workmanager (sincronização em background)
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class dev.fluttercommunity.workmanager.** { *; }

# 4. Google Protobuf (mensagens de índice e croqui serializadas)
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# 5. Google Play Services e Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

# 6. Firebase Suite (Analytics, Crashlytics, Perf, App Check, Remote Config)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# 7. Mobile Scanner (MLKit / CameraX)
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# 8. KotlinX Coroutines e Reflection
-dontwarn kotlinx.coroutines.**
-keepclassmembers class kotlinx.coroutines.** { *; }