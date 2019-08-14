import com.android.build.gradle.AppExtension
import com.android.build.gradle.api.ApplicationVariant
import groovy.lang.Closure

val buildScriptsDir: String by rootProject.extra
apply(from = "$buildScriptsDir/gradle/commonStaticAnalysis.gradle.kts")

buildscript {
    repositories {
        google()
        maven("https://plugins.gradle.org/m2/")
    }
    dependencies {
        classpath("com.android.tools.build:gradle:3.4.2")
    }
}

val getStaticAnalysisTaskNames: (Boolean, List<String>, ApplicationVariant?, Boolean, Boolean) -> List<String> by extra
val getIdeaFormatTask: (isAndroidProject: Boolean, sources: List<String>) -> Task by extra
val generateReport: (isAndroidProject: Boolean) -> Unit by extra



//val getStaticAnalysisTaskNames: Closure<List<String>> by extra
//val getIdeaFormatTask: Closure<Task> by extra
//val generateReport: Closure<Unit> by extra

gradle.projectsEvaluated {
    tasks.withType(JavaCompile::class.java) {
        options.compilerArgs = listOf(
                "-Xlint:cast",
                "-Xlint:divzero",
                "-Xlint:empty",
                "-Xlint:deprecation",
                "-Xlint:finally",
                "-Xlint:overrides",
                "-Xlint:path",
                "-Werror"
        )
    }

    val excludes = rootProject.extensions.findByName("staticAnalysisExcludes") as List<String>?
    val checkstyleEnabled = rootProject.extensions.findByName("checkstyleEnabled") as? Boolean ?: false
    val pmdEnabled = rootProject.extensions.findByName("pmdEnabled") as? Boolean ?: false

    val androidSources = getAndroidProjectSources(excludes)
    val androidStaticAnalysisTasks = getStaticAnalysisTaskNames(true, androidSources, null, checkstyleEnabled, pmdEnabled) as List<String>
    val androidIdeaFormatTask = getIdeaFormatTask(true, androidSources) as Task

    task("staticAnalysisWithFormatting") {
        androidStaticAnalysisTasks.forEach { task ->
            tasks.findByName(task)?.mustRunAfter(androidIdeaFormatTask)
        }
        dependsOn(androidIdeaFormatTask)
        dependsOn(androidStaticAnalysisTasks)
        doFirst {
            generateReport(true)
        }
    }

    task("staticAnalysis") {
        dependsOn(androidStaticAnalysisTasks)
        doFirst {
            generateReport(true)
        }
    }

    val serverStaticAnalysisTasks = getStaticAnalysisTaskNames(false, getServerProjectSources(excludes), null, checkstyleEnabled, pmdEnabled) as List<String>
    val serverIdeaFormatTask = getIdeaFormatTask(false, getServerProjectSources(excludes)) as Task

    task("serverStaticAnalysisWithFormatting") {
        serverStaticAnalysisTasks.forEach { task ->
            tasks.findByName(task)?.mustRunAfter(serverIdeaFormatTask)
        }
        dependsOn(serverIdeaFormatTask)
        dependsOn(serverStaticAnalysisTasks)
        doFirst {
            generateReport(false)
        }
    }

    task("serverStaticAnalysis") {
        dependsOn(serverStaticAnalysisTasks)
        doFirst {
            generateReport(false)
        }
    }

    pluginManager.withPlugin("com.android.application") {
        (rootProject.extensions.findByName("android") as AppExtension).applicationVariants.forEach { variant ->
            task("staticAnalysis") {
                val tasks = (getStaticAnalysisTaskNames(true, androidSources, variant, checkstyleEnabled, pmdEnabled) as List<String>)
                dependsOn(tasks)
                doFirst {
                    generateReport(true)
                }
            }
        }
    }
}

fun getServerProjectSources(excludes: List<String>?): List<String> {
    val sources = ArrayList<String>()
    val sourcesDirectory = File(project.projectDir.path, "src")

    for (sourceFlavorDirectory in sourcesDirectory.listFiles().orEmpty()) {
        val javaSourceDirectory = File(sourceFlavorDirectory.path, "java")
        val kotlinSourceDirectory = File(sourceFlavorDirectory.path, "kotlin")

        if (javaSourceDirectory.exists() && javaSourceDirectory.isDirectory) {
            sources.add(javaSourceDirectory.absolutePath)
        }
        if (kotlinSourceDirectory.exists() && kotlinSourceDirectory.isDirectory) {
            sources.add(kotlinSourceDirectory.absolutePath)
        }
    }
    return sources
}

fun getAndroidProjectSources(excludes: List<String>?): ArrayList<String> {
    val sources = ArrayList<String>()
    for (project in rootProject.subprojects) {
        if (project.subprojects.isNotEmpty() || (excludes != null && excludes.contains(project.path))) {
            continue
        }

        val sourcesDirectory = File(project.projectDir.path, "src")
        if (!sourcesDirectory.exists() || !sourcesDirectory.isDirectory) {
            continue
        }

        for (sourceFlavorDirectory in sourcesDirectory.listFiles().orEmpty()) {
            val javaSourceDirectory = File(sourceFlavorDirectory.path, "java")
            val kotlinSourceDirectory = File(sourceFlavorDirectory.path, "kotlin")

            if (javaSourceDirectory.exists() && javaSourceDirectory.isDirectory) {
                sources.add(javaSourceDirectory.absolutePath)
            }
            if (kotlinSourceDirectory.exists() && kotlinSourceDirectory.isDirectory) {
                sources.add(kotlinSourceDirectory.absolutePath)
            }
        }
    }
    return sources
}
