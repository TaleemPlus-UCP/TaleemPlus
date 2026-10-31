# Gradle Java Native Access Warning Fix

> **Date:** October 2026  
> **Component:** Gradle Daemon JVM / Native Platform Integration  
> **Target Environment:** Windows PowerShell / JDK 17+ / Gradle 9.1.0

---

## 1. Root Cause Analysis
Modern Java versions (Java 16+) enforce strict capsule encapsulation for restricted native methods (`System::load`) under JEP 396/403. When Gradle's internal library (`native-platform-0.22-milestone-28.jar`) executes within the Gradle Daemon JVM, it attempts to load native platform binaries without explicitly declaring module native access. The JVM emits a warning:
```text
WARNING: A restricted method in java.lang.System has been called
WARNING: java.lang.System::load has been called by net.rubygrapefruit.platform.internal.NativeLibraryLoader...
WARNING: Use --enable-native-access=ALL-UNNAMED to avoid a warning for callers in this module
```
While this warning is non-fatal and does not prevent successful compilation or APK building, it clutters standard output during Gradle execution.

---

## 2. Environment & Version Specification
* **Java Version:** JDK 17 (Eclipse Temurin / OpenJDK)
* **Gradle Version:** Gradle 9.1.0 (configured via `gradle-wrapper.properties`)
* **Android Gradle Plugin (AGP):** `9.0.1`
* **Kotlin Version:** `2.3.20`
* **Flutter Version:** `3.47.9` (Dart `3.13.7`)

---

## 3. Configuration Changes
To eliminate this warning gracefully without altering project functionality, we configured the Gradle JVM arguments in `android/gradle.properties` to allow native access (`--enable-native-access=ALL-UNNAMED`), preserving all existing memory and heap allocation settings:

```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError --enable-native-access=ALL-UNNAMED
```

---

## 4. Files Modified
* `android/gradle.properties` (Updated `org.gradle.jvmargs` with `--enable-native-access=ALL-UNNAMED`).

---

## 5. Verification Results
Running Gradle verification commands:
```powershell
cd android
.\gradlew --version
.\gradlew help
cd ..
flutter clean
flutter pub get
flutter build apk --debug
```
* Result: Gradle daemon successfully started with native access enabled, cleanly bypassing the restricted method warning while preserving full build success.
