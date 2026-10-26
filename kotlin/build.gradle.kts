plugins {
    kotlin("jvm") version "1.9.22"
    kotlin("plugin.serialization") version "1.9.22"
    `maven-publish`
}

group = "com.malviys.unii"
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

    testImplementation(kotlin("test"))
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.8.0")
}

tasks.test {
    useJUnitPlatform()
}

publishing {
    publications {
        create<MavenPublication>("mavenJava") {
            from(components["java"])
            groupId = "com.malviys.unii"
            artifactId = "unii-kotlin"
            version = "0.1.0"

            pom {
                name.set("unii-kotlin")
                description.set("Official Kotlin client SDK for Unii conversational AI platform")
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
                        email.set("dev@unii.dev")
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
