package static_analysis.linters

import org.gradle.api.Project
import static_analysis.errors.StaticAnalysisError
import static_analysis.plugins.StaticAnalysisExtension

interface Linter {
    val name: String
    fun getErrors(project: Project): List<StaticAnalysisError>
    fun setupForProject(project: Project, extension: StaticAnalysisExtension)
    fun getTaskNames(project: Project, buildType: String? = null): List<String>
}
