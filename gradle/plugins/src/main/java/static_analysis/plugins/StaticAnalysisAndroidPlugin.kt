package static_analysis.plugins

import com.android.build.gradle.AppExtension
import org.gradle.api.Project
import org.gradle.kotlin.dsl.getByType
import static_analysis.linters.AndroidLinter
import static_analysis.linters.DetektLinter
import static_analysis.linters.Linter
import java.util.Locale

class StaticAnalysisAndroidPlugin : StaticAnalysisPlugin() {

    override fun createStaticAnalysisTasks(project: Project, linters: List<Linter>) {
        project.subprojects {
            if (plugins.hasPlugin("com.android.application")) {

                extensions.getByType<AppExtension>().apply {
                    applicationVariants.forEach { variant ->
                        project.tasks.register("staticAnalysis${variant.name.capitalize()}") {
                        setupStaticAnalysisTask(linters, variant.name)
                        }
                    }

                    project.tasks.register("staticAnalysis") {
                        setupStaticAnalysisTask(
                                linters = linters,
                                buildVariant = applicationVariants.first { it.name.toLowerCase(Locale.ROOT).contains("debug") }.name
                        )
                    }
                }

            }
        }
    }

    //TODO: return CpdLinter after finding better way to disable it
    override fun createLinters(): List<Linter> = listOf(
            DetektLinter(),
            AndroidLinter()
    )

}
