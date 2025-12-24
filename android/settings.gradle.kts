pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // Order matters
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    // Prefer settings repos but don't fail if a project adds one (Flutter plugin does)
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        // Flutter engine artifacts (embedding, split APKs, etc.)
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        // Local engine repo inside the Flutter SDK (covers debug artifacts)
        val flutterSdkPath = run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            properties.getProperty("flutter.sdk") ?: ""
        }
        if (flutterSdkPath.isNotEmpty()) {
            maven { url = uri("$flutterSdkPath/bin/cache/artifacts/engine/android") }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP/Kotlin compatible with Flutter’s current toolchain
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.10" apply false
}

rootProject.name = "smart_plug"
include(":app")