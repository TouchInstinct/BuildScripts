
class AndroidStaticAnalysis extends StaticAnalysis {

    @Override
    void apply(final Project target) {
        super.apply(project)

        def excludes = target.extensions.findByName("staticAnalysisExcludes")
        def pmdEnabled = target.extensions.findByName("pmdEnabled") ?: false

        def androidSources = getAndroidProjectSources(excludes)
        def androidStaticAnalysisTasks = getStaticAnalysisTaskNames(true, androidSources, null, pmdEnabled)
        def androidIdeaFormatTask = getIdeaFormatTask(androidSources)

        project.configure(target) {
            tasks.withType(JavaCompile) {
                options.compilerArgs <<
                        "-Xlint:cast" <<
                        "-Xlint:divzero" <<
                        "-Xlint:empty" <<
                        "-Xlint:deprecation" <<
                        "-Xlint:finally" <<
                        "-Xlint:overrides" <<
                        "-Xlint:path" <<
                        "-Werror"
            }



            android.applicationVariants.all { variant ->
                task("staticAnalysis${variant.name.capitalize()}") {
                    dependsOn getStaticAnalysisTaskNames(true, androidSources, variant, pmdEnabled)
                    doFirst { generateReport(true) }
                }
            }
        }

        project.task('staticAnalysisWithFormatting') {
            if (androidIdeaFormatTask != null) {
                androidStaticAnalysisTasks.each { task ->
                    tasks.findByName(task).mustRunAfter(androidIdeaFormatTask)
                }
                dependsOn androidIdeaFormatTask
            }
            dependsOn androidStaticAnalysisTasks
            doFirst {
                generateReport(true)
            }
        }

        project.task('staticAnalysis') {
            dependsOn androidStaticAnalysisTasks
            doFirst {
                generateReport(true)
            }
        }

    }

    @Override
    List<String> getSources(excludes) {
        def sources = new ArrayList<String>()
        for (def project : rootProject.subprojects) {
            if (!project.subprojects.isEmpty() || (excludes != null && excludes.contains(project.path))) {
                continue
            }

            def sourcesDirectory = new File(project.projectDir.path, 'src')
            if (!sourcesDirectory.exists() || !sourcesDirectory.isDirectory()) {
                continue
            }

            for (def sourceFlavorDirectory : sourcesDirectory.listFiles()) {
                def javaSourceDirectory = new File(sourceFlavorDirectory.path, 'java')
                def kotlinSourceDirectory = new File(sourceFlavorDirectory.path, 'kotlin')

                if (javaSourceDirectory.exists() && javaSourceDirectory.isDirectory()) {
                    sources.add(javaSourceDirectory.absolutePath)
                }
                if (kotlinSourceDirectory.exists() && kotlinSourceDirectory.isDirectory()) {
                    sources.add(kotlinSourceDirectory.absolutePath)
                }
            }
        }
        return sources
    }

    @Override
    boolean isAndroidProject() {
        return true
    }

}
