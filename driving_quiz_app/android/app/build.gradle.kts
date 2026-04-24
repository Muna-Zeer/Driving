plugins {
    id("com.android.application")
    id("kotlin-android")
<<<<<<< HEAD
=======
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
>>>>>>> b650c70 (Generate new folders and set up flutter app well)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.driving_quiz_app"
    compileSdk = flutter.compileSdkVersion
<<<<<<< HEAD
    
    // CHANGE: We are hardcoding the version we found in your folder
    ndkVersion = "26.3.11579264" 
=======
    ndkVersion = flutter.ndkVersion
>>>>>>> b650c70 (Generate new folders and set up flutter app well)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
<<<<<<< HEAD
        applicationId = "com.example.driving_quiz_app"
        minSdk = 21 // Manually setting this helps bypass NDK compatibility errors
=======
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.driving_quiz_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
>>>>>>> b650c70 (Generate new folders and set up flutter app well)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
<<<<<<< HEAD
=======
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
>>>>>>> b650c70 (Generate new folders and set up flutter app well)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
<<<<<<< HEAD
}
=======
}
>>>>>>> b650c70 (Generate new folders and set up flutter app well)
