pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

gradle.beforeProject {
    buildscript.configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (
                requested.group == "com.android.tools.build" &&
                    requested.name == "gradle" &&
                    requested.version in
                        setOf("8.7.2", "8.12.1", "8.13.0", "8.13.2")
            ) {
                useVersion("8.13.1")
                because(
                    "Usa el parche compatible disponible para plugins Flutter nativos",
                )
            }
            if (
                requested.group == "org.jetbrains.kotlin" &&
                    requested.name == "kotlin-gradle-plugin" &&
                    requested.version == "2.4.10"
            ) {
                useVersion("2.3.20")
                because("Alinea mobile_scanner con Kotlin del proyecto y la caché local")
            }
        }
    }
}

include(":app")
