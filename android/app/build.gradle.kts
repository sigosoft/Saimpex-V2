import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing with V1's keystore (V2 ships as an update of V1, so it
// must be signed with the same key). The keystore and its passwords stay out
// of git: android/key.properties (ignored) holds storeFile, storePassword,
// keyAlias and keyPassword; see android/key.properties.example. Without them,
// release builds fall back to the debug key.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { stream -> keystoreProperties.load(stream) }
}
val hasReleaseKey = listOf("storeFile", "storePassword", "keyAlias")
    .all { key -> !keystoreProperties.getProperty(key).isNullOrBlank() }

android {
    namespace = "com.example.saimpex_v2"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications needs java.time on older Android.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // V1's application ID: the V2 app ships as an update of V1, and the
        // Firebase project saimpex-customer (google-services.json) is for it.
        applicationId = "app.saimpex"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        // Google Play requires a recent target API level for updates.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (hasReleaseKey) "release" else "debug",
            )
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// An older plugin still pulls in firebase-iid, whose classes are now part of
// firebase-messaging; keeping both fails the duplicate-class check.
configurations.all {
    exclude(group = "com.google.firebase", module = "firebase-iid")
}
