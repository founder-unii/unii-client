plugins {
    kotlin("jvm") version "1.9.22"
    kotlin("plugin.serialization") version "1.9.22"
    `maven-publish`
}

group = "io.github.dev-unii"
version = "0.1.0"

repositories {
    mavenCentral()
}

java {
    withSourcesJar()
    withJavadocJar()
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.8.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:okhttp-sse:4.12.0")

    testImplementation(kotlin("test-junit5"))
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.8.0")
}

tasks.test {
    useJUnitPlatform()
}

publishing {
    publications {
        create<MavenPublication>("mavenJava") {
            from(components["java"])
            groupId = "io.github.dev-unii"
            artifactId = "unii-kotlin"
            version = "0.1.0"

            pom {
                name.set("unii-kotlin")
                description.set("Official Kotlin client SDK for Unii conversational AI platform")
                url.set("https://github.com/founder-unii/unii-client")
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
                    connection.set("scm:git:git://github.com/founder-unii/unii-client.git")
                    developerConnection.set("scm:git:ssh://github.com:founder-unii/unii-client.git")
                    url.set("https://github.com/founder-unii/unii-client")
                }
            }
        }
    }
}
