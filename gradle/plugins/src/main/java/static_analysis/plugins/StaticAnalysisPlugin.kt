package static_analysis.plugins

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.kotlin.dsl.create
import org.gradle.kotlin.dsl.getByType
import static_analysis.linters.Linter
import static_analysis.utils.ReportGenerator

abstract class StaticAnalysisPlugin : Plugin<Project> {

    companion object {
        const val DETEKT_ID = "io.gitlab.arturbosch.detekt"
        const val CPD_ID = "de.aaschmid.cpd"
        const val STATIC_ANALYSIS_EXT_NAME = "staticAnalysis"
    }

    override fun apply(target: Project) {

        with(target) {
            pluginManager.apply(CPD_ID)
            pluginManager.apply(DETEKT_ID)

            extensions.create<StaticAnalysisExtension>(STATIC_ANALYSIS_EXT_NAME)

            val linters = createLinters()

            afterEvaluate {
                linters.forEach { it.setupForProject(target, extensions.getByType()) }
            }

            gradle.projectsEvaluated {
                createStaticAnalysisTasks(target, linters)
            }
        }
    }

    fun Task.setupStaticAnalysisTask(linters: List<Linter>, buildVariant: String? = null) {
        doFirst { ReportGenerator.generate(linters, project) }
        dependsOn(*(linters.map { it.getTaskNames(project, buildVariant) }.flatten().toTypedArray()))
    }

    abstract fun createLinters(): List<Linter>
    abstract fun createStaticAnalysisTasks(project: Project, linters: List<Linter>)

}
