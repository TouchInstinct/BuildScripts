package static_analysis.linters

import io.gitlab.arturbosch.detekt.Detekt
import org.gradle.api.Project
import static_analysis.errors.DetektError
import static_analysis.errors.StaticAnalysisError
import static_analysis.plugins.StaticAnalysisExtension
import static_analysis.utils.getSources
import static_analysis.utils.typedChildren
import static_analysis.utils.xmlParser

class DetektLinter : Linter {

    override val name: String = "Detekt"

    override fun getErrors(project: Project): List<StaticAnalysisError> = xmlParser(project.getDetektReportFile())
            .typedChildren()
            .filter { fileNode -> fileNode.name() == "file" }
            .map { fileNode ->
                fileNode
                        .typedChildren()
                        .filter { it.name() == "error" }
                        .map { errorNode ->
                            DetektError(
                                    filePath = fileNode.attribute("name") as String,
                                    fileLine = errorNode.attribute("line") as String,
                                    errorId = errorNode.attribute("source") as String,
                                    description = errorNode.attribute("message") as String
                            )
                        }
            }
            .flatten()

    override fun setupForProject(project: Project, extension: StaticAnalysisExtension) {
        project
                .tasks
                .withType(Detekt::class.java) {
                    exclude("**/test/**")
                    exclude("resources/")
                    exclude("build/")
                    exclude("tmp/")
                    jvmTarget = "1.8"

                    config.setFrom(project.files("${extension.buildScriptDir!!}/static_analysis_configs/detekt-config.yml"))
                    reports {
                        txt.enabled = false
                        html.enabled = false
                        xml {
                            enabled = true
                            destination = project.getDetektReportFile()
                        }
                    }

                    source = project.getSources(extension.excludes)
                }
    }

    override fun getTaskNames(project: Project, buildType: String?): List<String> = listOf(":detekt")

    private fun Project.getDetektReportFile() = file("${rootProject.buildDir}/reports/detekt.xml")

}
