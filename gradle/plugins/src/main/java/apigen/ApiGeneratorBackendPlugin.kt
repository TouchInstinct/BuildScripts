package apigen

import org.gradle.api.Project

class ApiGeneratorBackendPlugin : ApiGeneratorPlugin() {

    override fun apply(target: Project) {
        super.apply(target)

        val extension = target.getExtension()

        extension.outputDirPath = target.file("src/main/kotlin").path
        extension.recreateOutputDir = false
        extension.outputLanguage = OutputLanguage.KotlinServer

    }
}
