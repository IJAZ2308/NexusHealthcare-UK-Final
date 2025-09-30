plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.dr_shahin_uk"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.dr_shahin_uk"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            // minifyEnabled = true // Optional
            // shrinkResources = true // Optional
        }
    }
}

dependencies {
    // Core library desugaring for Java 8 features
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
