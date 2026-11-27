import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Llave de firma de la versión release. android/key.properties NO se sube a
// git (tiene las contraseñas). Si no existe (por ejemplo, en la compu de
// Kinberly), la versión release se firma con la llave de depuración y la app
// sigue compilando normal.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val tieneLlave = keystorePropertiesFile.exists()
if (tieneLlave) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // El namespace se queda así a propósito: es interno (el paquete de
    // MainActivity). El identificador público de la app es applicationId.
    namespace = "com.example.studdy_plan_proyecto"
   // flutter_local_notifications y androidx.core piden compilar contra 37.
    // (No cambia en qué celulares funciona: eso lo decide minSdk.)
    compileSdk = maxOf(flutter.compileSdkVersion, 37)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Necesario para flutter_local_notifications (recordatorios).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.diegohernandez.studyplan"
        // cloud_firestore necesita Android 6.0 (API 23) o más nuevo.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        // Toma la versión de pubspec.yaml (version: 1.0.0+1).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (tieneLlave) {
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
            signingConfig = if (tieneLlave) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
    // Para flutter_local_notifications (ver isCoreLibraryDesugaringEnabled).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}