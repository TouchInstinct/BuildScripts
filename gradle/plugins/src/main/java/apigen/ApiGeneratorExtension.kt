package apigen

open class ApiGeneratorExtension(
        var pathToApiSchemes: String? = null,
        var outputPackageName: String = "",
        var outputDirPath: String = "",
        var recreateOutputDir: Boolean = false,
        var outputLanguage: OutputLanguage? = null
)

sealed class OutputLanguage(val argName: String, val methodOutputType: MethodOutputType? = null) {
    object KotlinServer : OutputLanguage("KOTLIN_SERVER")
    class KotlinAndroid(methodOutputType: MethodOutputType = MethodOutputType.Rx) : OutputLanguage("KOTLIN", methodOutputType)
    object Java : OutputLanguage("JAVA")
    object Swift : OutputLanguage("SWIFT")
}

sealed class MethodOutputType(val argName: String) {
    object Rx : MethodOutputType("REACTIVE")
    object RetrofitCall : MethodOutputType("CALL")
    object Coroutine : MethodOutputType("COROUTINE")
}
