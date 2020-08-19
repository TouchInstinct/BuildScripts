package apigen

import org.gradle.api.Project

class ApiGeneratorBackendPlugin : ApiGeneratorPlugin() {

    override fun apply(target: Project) {
        super.apply(target)

        with(target) {
            val extension = getExtension()

            extension.outputDirPath = file("src/main/kotlin").path
            extension.recreateOutputDir = false
            extension.outputLanguage = OutputLanguage.KotlinServer

        }
    }
}
