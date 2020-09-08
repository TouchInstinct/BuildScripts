package apigen

import com.android.build.gradle.AppExtension
import com.android.build.gradle.LibraryExtension
import org.gradle.api.Project
import org.gradle.api.tasks.compile.JavaCompile
import org.gradle.kotlin.dsl.findByType
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

class ApiGeneratorAndroidPlugin : ApiGeneratorPlugin() {

    override fun apply(target: Project) {
        super.apply(target)

        with(target) {
            val extension = getExtension()
            val outputDir = getDirectoryForGeneration()

            extension.outputDirPath = outputDir.path
            extension.recreateOutputDir = true

            afterEvaluate {
                extensions.findByType<LibraryExtension>()?.apply {
                    sourceSets.getByName("main")
                            .java
                            .srcDir(outputDir)
                }
                extensions.findByType<AppExtension>()?.apply {
                    sourceSets.getByName("main")
                            .java
                            .srcDir(outputDir)
                }
                tasks
                        .filterIsInstance<KotlinCompile>()
                        .forEach { it.source(outputDir) }

                tasks
                        .filterIsInstance<JavaCompile>()
                        .forEach { it.source(outputDir) }
            }
        }
    }

    private fun Project.getDirectoryForGeneration() = file("$buildDir/generated/api")

}
