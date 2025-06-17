plugins {
    id("com.android.library")
    kotlin("android")
}

android {
    namespace = "co.epsilondelta.orion_flutter"
    compileSdk = 35

    defaultConfig {
        minSdk = 21
        targetSdk = 34
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
}

repositories {
    flatDir {
        dirs("libs") // 👈 Tells Gradle to look for .aar here
    }
    google()
    mavenCentral()
}

dependencies {
    implementation(name = "orion_flutter-release", ext = "aar") // 👈 Your binary SDK
}