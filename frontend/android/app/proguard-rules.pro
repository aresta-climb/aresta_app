# Regras do ProGuard / R8 para o Aresta App

# 1. Manter atributos essenciais para stacktraces e annotations no Crashlytics
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,SourceFile,LineNumberTable

# 2. Suprimir warnings de classes opcionais ou não utilizadas em runtime
-dontwarn com.google.android.play.core.**
-dontwarn com.google.protobuf.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
-dontwarn com.google.mlkit.**
-dontwarn kotlinx.coroutines.**

# 3. KotlinX Coroutines e Reflection
-keepclassmembers class kotlinx.coroutines.** { *; }