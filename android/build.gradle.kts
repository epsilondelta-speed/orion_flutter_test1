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
    google()
    mavenCentral()
     flatDir {
        dirs("libs") // 👈 Tells Gradle to look for .aar here
    }
}

dependencies {
   implementation(":orion_flutter-release@aar") // ✅ correct in .kts
}