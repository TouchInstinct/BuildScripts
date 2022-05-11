package static_analysis.linters

import com.android.build.gradle.AppPlugin
import org.gradle.api.Project
import static_analysis.errors.AndroidLintError
import static_analysis.errors.StaticAnalysisError
import static_analysis.plugins.StaticAnalysisExtension
import static_analysis.utils.typedChildren
import static_analysis.utils.xmlParser

class AndroidLinter : Linter {

    override val name: String = "Android lint"

    override fun getErrors(project: Project): List<StaticAnalysisError> = xmlParser(project.getLintReportFile())
            .typedChildren()
            .filter { it.name() == "issue" && (it.attribute("severity") as String) == "Error" }
            .map { errorNode ->
                errorNode
                        .typedChildren()
                        .filter { it.name() == "location" }
                        .map { locationNode ->
                            AndroidLintError(
                                    filePath = locationNode.attribute("file") as String,
                                    fileLine = locationNode.attribute("line") as String?,
                                    errorId = errorNode.attribute("id") as String,
                                    description = errorNode.attribute("message") as String
                            )
                        }
            }
            .flatten()

    override fun setupForProject(project: Project, extension: StaticAnalysisExtension) {
        // Make sure to set lint options manually in modules gradle file
        // Otherwise you will get java.io.FileNotFoundException

        // See issue: https://github.com/TouchInstinct/BuildScripts/issues/310
    }

    override fun getTaskNames(project: Project, buildType: String?): List<String> {
        if (buildType == null) {
            throw IllegalStateException("Build type must not be null in android linter")
        }

        return project
                .subprojects
                .filter { it.plugins.hasPlugin(AppPlugin::class.java) }
                .mapNotNull { subproject: Project ->
                    subproject
                            .tasks
                            .find { task -> task.name.equals("lint$buildType", ignoreCase = true) }
                            ?.path
                }
    }

    private fun Project.getLintReportFile() = file("${rootProject.buildDir}/reports/lint-report.xml")

}
