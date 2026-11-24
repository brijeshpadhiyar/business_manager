import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

val releaseStoreFilePath = keystoreProperties.getProperty("storeFile")?.trim().orEmpty()
val releaseStorePassword = keystoreProperties.getProperty("storePassword")?.trim().orEmpty()
val releaseKeyAlias = keystoreProperties.getProperty("keyAlias")?.trim().orEmpty()
val releaseKeyPassword = keystoreProperties.getProperty("keyPassword")?.trim().orEmpty()
val hasReleaseSigning =
    keystorePropertiesFile.exists() &&
    releaseStoreFilePath.isNotEmpty() &&
    releaseStorePassword.isNotEmpty() &&
    releaseKeyAlias.isNotEmpty() &&
    releaseKeyPassword.isNotEmpty() &&
    rootProject.file(releaseStoreFilePath).exists()

android {
    namespace = "com.brijesh.stitchflow"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.brijesh.stitchflow"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        resValues = true
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "StitchFlow Dev")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "StitchFlow")
        }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(releaseStoreFilePath)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fail safely on production or generic release tasks instead of silently
                // shipping a debug-signed production artifact. Allow dev release builds
                // (com.brijesh.stitchflow.dev) to fall back to debug signing for local QA
                // with an explicit console warning.
                val taskNames = gradle.startParameter.taskNames.map { it.lowercase() }
                val releaseTasks = taskNames.filter { it.contains("release") }
                val hasProdOrGenericReleaseTask = releaseTasks.any { !it.contains("devrelease") }
                if (hasProdOrGenericReleaseTask) {
                    throw GradleException(
                        "Missing or incomplete Android release signing config for production release. " +
                            "Create android/key.properties (see android/key.properties.example) " +
                            "pointing to your local upload keystore before building a prod release artifact."
                    )
                }
                if (releaseTasks.isNotEmpty()) {
                    logger.warn(
                        "WARNING: android/key.properties not found. Signing dev release APK " +
                            "(com.brijesh.stitchflow.dev) with debug keystore for local QA only."
                    )
                    signingConfig = signingConfigs.getByName("debug")
                }
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
