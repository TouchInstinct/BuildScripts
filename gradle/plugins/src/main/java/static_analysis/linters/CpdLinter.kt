package static_analysis.linters

import de.aaschmid.gradle.plugins.cpd.Cpd
import de.aaschmid.gradle.plugins.cpd.CpdExtension
import org.gradle.api.Project
import org.gradle.kotlin.dsl.findByType
import org.gradle.kotlin.dsl.withType
import static_analysis.errors.CpdError
import static_analysis.errors.StaticAnalysisError
import static_analysis.plugins.StaticAnalysisExtension
import static_analysis.utils.getSources
import static_analysis.utils.typedChildren
import static_analysis.utils.xmlParser

class CpdLinter : Linter {

    override val name: String = "CPD"

    override fun getErrors(project: Project): List<StaticAnalysisError> = xmlParser(project.getCpdReportFile())
            .typedChildren()
            .filter { it.name() == "duplication" }
            .map { duplicationNode ->

                val children = duplicationNode
                        .typedChildren()

                CpdError(
                        duplications = children
                                .filter { it.name() == "file" }
                                .map { fileNode -> fileNode.attribute("path") as String to fileNode.attribute("line") as String },
                        codeFragment = children.findLast { it.name() == "codefragment" }!!.text()
                )

            }

    override fun setupForProject(project: Project, extension: StaticAnalysisExtension) {
        project.extensions.findByType<CpdExtension>()!!.apply {
            isSkipLexicalErrors = true
            language = "kotlin"
            minimumTokenCount = 60
        }
        project.tasks.withType<Cpd> {
            reports.xml.destination = project.getCpdReportFile()
            ignoreFailures = true
            source = project.getSources(extension.excludes)
        }
    }

    override fun getTaskNames(project: Project, buildType: String?): List<String> = project
            .rootProject
            .tasks
            .withType<Cpd>()
            .map(Cpd::getPath)

    private fun Project.getCpdReportFile() = file("${rootProject.buildDir}/reports/cpd.xml")

}
