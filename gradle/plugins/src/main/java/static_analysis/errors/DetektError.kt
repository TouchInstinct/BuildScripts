package static_analysis.errors

class DetektError(
        private val filePath: String,
        private val fileLine: String,
        private val errorId: String,
        private val description: String
) : StaticAnalysisError {

    override fun print(count: Int): String = "\n$count. Detekt. $description ($errorId)\n\tat [$filePath:$fileLine]"

}
