# ML Kit Text Recognition ProGuard Rules
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# General ML Kit rules to prevent R8 from stripping necessary classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
