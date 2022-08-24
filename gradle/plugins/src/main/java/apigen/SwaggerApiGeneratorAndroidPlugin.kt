package apigen

import org.gradle.api.Action
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.kotlin.dsl.create
import org.gradle.kotlin.dsl.dependencies
import org.gradle.kotlin.dsl.repositories

class SwaggerApiGeneratorAndroidPlugin : Plugin<Project> {

    companion object {
        const val GENERATOR_CONFIG = "swaggerCodegen"
        const val GENERATOR_VERSION = "3.0.34"
        const val TI_GENERATOR_CONFIG = "TIKotlin-swagger-codegen"
        const val TI_GENERATOR_VERSION = "1.0.0"
        const val GENERATOR_EXT_NAME = "swaggerApiGenerator"
    }

    override fun apply(target: Project) {
        with(target) {
            repositories {
                maven {
                    url = uri("https://maven.dev.touchin.ru")
                    metadataSources {
                        artifact()
                    }
                }
            }

            configurations.create(GENERATOR_CONFIG)
            configurations.create(TI_GENERATOR_CONFIG)

            dependencies {
                add(TI_GENERATOR_CONFIG,  "ru.touchin:TIKotlin-swagger-codegen:$TI_GENERATOR_VERSION")
                add(GENERATOR_CONFIG,  "io.swagger.codegen.v3:swagger-codegen-cli:$GENERATOR_VERSION")
            }

            extensions.create<SwaggerApiGeneratorExtension>(GENERATOR_EXT_NAME)

            val apiGenTask = createSwaggerApiGeneratorTask()

            gradle.projectsEvaluated {
                tasks.getByName("preBuild").dependsOn(apiGenTask)
            }
        }
    }

    protected fun Project.getExtension(): SwaggerApiGeneratorExtension = extensions.getByName(GENERATOR_EXT_NAME) as SwaggerApiGeneratorExtension

    private fun Project.createSwaggerApiGeneratorTask(): Task = tasks.create(GENERATOR_CONFIG).doLast {

        val extension = getExtension()

        val taskWorkingDir = extension.taskWorkingDir ?: throw IllegalStateException("Configure taskWorkingDir for swagger generator plugin")
        val apiSchemesFilePath = extension.apiSchemesFilePath ?: throw IllegalStateException("Configure sourceFilePath for swagger generator plugin")
        val outputDir = extension.outputDir ?: throw IllegalStateException("Configure outputDir for swagger generator plugin")
        val projectName = extension.projectName ?: throw IllegalStateException("Configure projectName for swagger generator plugin")

        javaexec {
            workingDir = file(taskWorkingDir)
            classpath = files(configurations.getByName(GENERATOR_CONFIG).asPath,
                    configurations.getByName(TI_GENERATOR_CONFIG).asPath)
            main = "io.swagger.codegen.v3.cli.SwaggerCodegen"
            args = listOfNotNull(
                "generate",
                "-i",
                apiSchemesFilePath,
                "-l",
                "TIKotlinCodegen",
                "-o",
                outputDir,
                "--additional-properties",
                "projectName=$projectName"
            )
        }
    }

}

open class SwaggerApiGeneratorExtension(
        var taskWorkingDir: String? = null,
        var apiSchemesFilePath: String? = null,
        var outputDir: String? = null,
        var projectName: String? = null
)

fun Project.swaggerApiGenerator(configure: Action<SwaggerApiGeneratorExtension>): Unit =
        (this as org.gradle.api.plugins.ExtensionAware).extensions.configure("swaggerApiGenerator", configure)
