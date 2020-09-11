package apigen

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.kotlin.dsl.create
import org.gradle.kotlin.dsl.dependencies
import org.gradle.kotlin.dsl.repositories

abstract class ApiGeneratorPlugin : Plugin<Project> {

    companion object {
        const val API_GENERATOR_CONFIG = "apiGenerator"
        const val API_GENERATOR_EXT_NAME = "apiGenerator"
        const val API_GENERATOR_DEFAULT_VERSION = "1.4.0-beta5"
    }

    override fun apply(target: Project) {
        with(target) {
            repositories {
                maven {
                    url = uri("https://dl.bintray.com/touchin/touchin-tools")
                    metadataSources {
                        artifact()
                    }
                }
            }

            configurations.create(API_GENERATOR_CONFIG)

            dependencies {
                add(API_GENERATOR_CONFIG, "ru.touchin:api-generator:$API_GENERATOR_DEFAULT_VERSION")
            }

            extensions.create<ApiGeneratorExtension>(API_GENERATOR_EXT_NAME)

            val apiGenTask = createApiGeneratorTask()

            gradle.projectsEvaluated {
                tasks.getByName("preBuild").dependsOn(apiGenTask)
            }
        }
    }

    protected fun Project.getExtension(): ApiGeneratorExtension = extensions.getByName(API_GENERATOR_EXT_NAME) as ApiGeneratorExtension

    private fun Project.createApiGeneratorTask(): Task = tasks.create(API_GENERATOR_CONFIG).doLast {

        val extension = getExtension()

        val pathToApiSchemes = extension.pathToApiSchemes ?: throw IllegalStateException("Configure path to api schemes for api generator plugin")
        val outputLanguage = extension.outputLanguage ?: throw IllegalStateException("Configure output language code for api generator plugin")

        javaexec {
            main = "-jar"
            workingDir = rootDir
            args = listOfNotNull(
                    configurations.getByName("apiGenerator").asPath,
                    "generate-client-code",
                    "--output-language",
                    outputLanguage.argName,
                    "--specification-path",
                    pathToApiSchemes,
                    "--kotlin-methods-generation-mode".takeIf { outputLanguage.methodOutputType != null },
                    outputLanguage.methodOutputType?.argName,
                    "--output-path",
                    extension.outputDirPath,
                    "--package-name",
                    extension.outputPackageName,
                    "--recreate_output_dirs",
                    extension.recreateOutputDir.toString()
            )
        }
    }

}
