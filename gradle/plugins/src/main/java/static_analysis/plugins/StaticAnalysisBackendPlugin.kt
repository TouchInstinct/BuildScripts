package static_analysis.plugins

import org.gradle.api.Project
import static_analysis.linters.CpdLinter
import static_analysis.linters.DetektLinter
import static_analysis.linters.Linter

class StaticAnalysisBackendPlugin : StaticAnalysisPlugin() {

    override fun createStaticAnalysisTasks(project: Project, linters: List<Linter>) {
        project.tasks.register("staticAnalysis") {
            setupStaticAnalysisTask(linters)
        }
    }

    override fun createLinters(): List<Linter> = listOf(
            CpdLinter(),
            DetektLinter()
    )

}
