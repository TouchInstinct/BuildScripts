package static_analysis.errors

class AndroidLintError(
        private val filePath: String,
        private val fileLine: String?,
        private val errorId: String,
        private val description: String
) : StaticAnalysisError {

    override fun print(count: Int): String = "\n$count. Android Lint. $description ($errorId)\n\tat [$filePath$fileLinePrefix]"

    private val fileLinePrefix: String
        get() = fileLine?.let { ":$it" }.orEmpty()

}
