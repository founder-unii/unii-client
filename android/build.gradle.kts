plugins {
    id("com.android.library")
    kotlin("android")
    kotlin("plugin.serialization")
    `maven-publish`
}

group = "com.malviys.unii"
version = "0.1.0"

android {
    namespace = "com.malviys.unii.compose"
    compileSdk = 34

    defaultConfig {
        minSdk = 24
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.8"
    }

    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }
}

dependencies {
    api("com.malviys.unii:unii-kotlin:0.1.0")

    val composeBom = platform("androidx.compose:compose-bom:2024.02.00")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.foundation:foundation-layout")
    implementation("androidx.compose.runtime:runtime")

    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.7.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.8.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.8.0")
}

afterEvaluate {
    publishing {
        publications {
            create<MavenPublication>("release") {
                from(components["release"])
                groupId = "com.malviys.unii"
                artifactId = "unii-compose"
                version = "0.1.0"

                pom {
                    name.set("unii-compose")
                    description.set("Official Android & Jetpack Compose SDK for Unii conversational AI platform")
                    url.set("https://github.com/unii-founder/unii-client")
                    licenses {
                        license {
                            name.set("MIT License")
                            url.set("https://opensource.org/licenses/MIT")
                            distribution.set("repo")
                        }
                    }
                    developers {
                        developer {
                            id.set("unii")
                            name.set("Unii Team")
                            email.set("dev@getunii.com")
                        }
                    }
                    scm {
                        connection.set("scm:git:git://github.com/unii-founder/unii-client.git")
                        developerConnection.set("scm:git:ssh://github.com:unii-founder/unii-client.git")
                        url.set("https://github.com/unii-founder/unii-client")
                    }
                }
            }
        }
    }
}
