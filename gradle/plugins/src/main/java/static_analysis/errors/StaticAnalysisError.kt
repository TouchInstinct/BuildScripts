package static_analysis.errors

interface StaticAnalysisError {
    fun print(count: Int): String
}
