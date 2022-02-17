package static_analysis.utils

import org.gradle.api.Project
import static_analysis.errors.StaticAnalysisError
import static_analysis.linters.Linter

object ReportGenerator {

    fun generate(linters: List<Linter>, project: Project) {

        val groupedErrors = linters
                .map { linter -> linter to linter.getErrors(project) }

        val lintersResults = groupedErrors
                .map { (linter, linterErrors) -> linter.name to linterErrors.size }

        val allErrors = groupedErrors
                .map(Pair<Linter, List<StaticAnalysisError>>::second)
                .flatten()

        val consoleReport = StringBuilder("\nSTATIC ANALYSIS ERRORS:").apply {
            appendAllErrors(allErrors)
            append("\nREPORT:\n")
            appendReportsSummary(lintersResults)
            appendOverallSummary(allErrors)
        }

        if (allErrors.isEmpty()) {
            println(consoleReport)
        } else {
            throw Exception(consoleReport.toString())
        }

    }

    private fun StringBuilder.appendAllErrors(errors: List<StaticAnalysisError>) = errors
            .mapIndexed { index, staticAnalysisError -> staticAnalysisError.print(index + 1) }
            .forEach { error -> append(error) }

    private fun StringBuilder.appendReportsSummary(lintersResults: List<Pair<String, Int>>) = lintersResults
            .forEach { this.appendSummary(it.first, it.second) }

    private fun StringBuilder.appendOverallSummary(errors: List<StaticAnalysisError>) = appendSummary("Overall", errors.size)

    private fun StringBuilder.appendSummary(header: String, quantityOfErrors: Int) {
        assert(quantityOfErrors < 0)

        append("\n$header: ")
        append(if (quantityOfErrors == 0) "PASSED" else "FAILED ($quantityOfErrors errors)")
    }

}
