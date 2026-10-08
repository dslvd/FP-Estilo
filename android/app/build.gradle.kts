plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Release signing.
//
// A real keystore is used when android/key.properties exists (that file and
// the .jks it points at are gitignored, so no secrets reach the repository).
// When it is absent — a fresh clone, or CI — the build falls back to the debug
// keys so `flutter build apk --release` still produces an installable APK.
// ---------------------------------------------------------------------------
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreAvailable = keystorePropertiesFile.exists()
if (keystoreAvailable) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.estilo.plantpal"
    compileSdk = flutter.compileSdkVersion

    // PlantPal has no native C/C++ sources, so nothing here is compiled with
    // the NDK. A version is pinned anyway because the Flutter Gradle Plugin
    // asks for one, and leaving it unset makes the Android Gradle Plugin
    // download a different (multi-gigabyte) NDK release than the one already
    // installed. Pinning to what is present keeps builds offline-reproducible.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.estilo.plantpal"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreAvailable) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystoreAvailable) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
