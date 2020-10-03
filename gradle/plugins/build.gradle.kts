import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    `java-gradle-plugin`
    `kotlin-dsl`
}

// The kotlin-dsl plugin requires a repository to be declared
repositories {
    jcenter()
    google()
}

dependencies {
    // android gradle plugin, required by custom plugin
    implementation("com.android.tools.build:gradle:4.0.1")

    implementation("io.gitlab.arturbosch.detekt:detekt-gradle-plugin:1.10.0")
    implementation("de.aaschmid:gradle-cpd-plugin:3.1")

    // kotlin plugin, required by custom plugin
    implementation(kotlin("gradle-plugin", embeddedKotlinVersion))

    gradleKotlinDsl()
    implementation(kotlin("stdlib-jdk8"))
}

val compileKotlin: KotlinCompile by tasks
compileKotlin.kotlinOptions {
    jvmTarget = "1.8"
}

gradlePlugin {
    plugins {
        create("api-generator-android") {
            id = "api-generator-android"
            implementationClass = "apigen.ApiGeneratorAndroidPlugin"
        }
        create("api-generator-backend") {
            id = "api-generator-backend"
            implementationClass = "apigen.ApiGeneratorBackendPlugin"
        }
        create("static-analysis-android") {
            id = "static-analysis-android"
            implementationClass = "static_analysis.plugins.StaticAnalysisAndroidPlugin"
        }
        create("static-analysis-backend") {
            id = "static-analysis-backend"
            implementationClass = "static_analysis.plugins.StaticAnalysisBackendPlugin"
        }
    }
}
