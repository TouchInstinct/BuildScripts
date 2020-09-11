package static_analysis.errors

class CpdError(
        private val duplications: List<Pair<String, String>>,
        private val codeFragment: String
) : StaticAnalysisError {

    override fun print(count: Int): String = "\n$count. CPD. Code duplication in files: " +
            duplications.joinToString(separator = "") { (file, line) -> "\n\t[$file:$line]" } +
            "\n\n  Duplicated code:\n\n$codeFragment\n"

}
