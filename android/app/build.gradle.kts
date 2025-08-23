plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add Firebase plugin
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.example.hydracat_test"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.hydracat_test"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "com.example.hydracat_test"
            resValue("string", "app_name", "HydraCat Dev")
        }
        create("prod") {
            dimension = "environment"
            applicationId = "com.example.hydracat"
            resValue("string", "app_name", "HydraCat")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Configure Google Services for each flavor
android.applicationVariants.all {
    val variant = this
    variant.outputs.all {
        val output = this
        if (output is com.android.build.gradle.internal.api.BaseVariantOutputImpl) {
            val flavorName = variant.flavorName
            val googleServicesFile = when (flavorName) {
                "dev" -> "../../.firebase/dev/google-services.json"
                "prod" -> "../../.firebase/prod/google-services.json"
                else -> "../../.firebase/dev/google-services.json"
            }
            
            // Copy the appropriate google-services.json for this flavor
            copy {
                from(googleServicesFile)
                into(".")
                rename { "google-services.json" }
            }
        }
    }
}
