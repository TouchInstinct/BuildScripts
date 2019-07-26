import org.apache.tools.ant.taskdefs.condition.Os

abstract class StaticAnalysis implements Plugin<Project> {

    abstract List<String> getSources()

    abstract boolean isAndroidProject()

    @Override
    void apply(final Project target) {
        project.configure(target) {
            apply plugin: 'cpd'
            apply plugin: 'pmd'
            apply plugin: 'io.gitlab.arturbosch.detekt'

            repositories {
                maven { url "http://dl.bintray.com/touchin/touchin-tools" }
            }

            dependencies {
                pmd 'net.sourceforge.pmd:pmd-core:6.13.0'
                pmd 'net.sourceforge.pmd:pmd-java:6.13.0'
            }

            cpd {
                skipLexicalErrors = true
            }

            detekt {
                input = files("${rootDir}")
                config = files("$buildScriptsDir/kotlin/detekt-config.yml")
                parallel = true

                reports {
                    html {
                        enabled = true
                        destination = file("${project.buildDir}/reports/kotlin-detekt.html")
                    }
                    xml {
                        enabled = true
                        destination = file("${project.buildDir}/reports/kotlin-detekt.xml")
                    }
                }

            }

        }

        project.tasks.withType(io.gitlab.arturbosch.detekt.Detekt) {
            include("src/main/java/**")
            include("src/main/kotlin/**")
        }
    }

    private List<String> getStaticAnalysisTaskNames(
            final boolean isAndroidProject,
            final List<String> sources,
            final boolean buildVariant,
            final boolean pmdEnabled
    ) {
        def tasksNames = new ArrayList<String>()
        try {
            tasksNames.add(getCpdTask(sources))
            tasksNames.add(getKotlinDetektTask())
            if (isAndroidProject) {
                if (pmdEnabled) {
                    tasksNames.add(getPmdTask(sources))
                }
                tasksNames.add(getLintTask(buildVariant))
            }
        } catch (Exception exception) {
            println(exception.toString())
        }
        return tasksNames
    }

    private Task getIdeaFormatTask() {
        if (System.getenv("IDEA_HOME") == null) {
            return null
        }
        return tasks.create("ideaFormat_$project.name", Exec) {
            def inspectionPath
            def params = ["-r", "-mask", "*.java,*.kt,*.xml"]
            for (String source : getSources()) {
                params.add(source)
            }

            if (Os.isFamily(Os.FAMILY_WINDOWS)) {
                inspectionPath = ['cmd', '/c', "\"${ideaPath}\\bin\\format.bat\" ${params.join(" ")}"]
            } else {
                inspectionPath = ["$ideaPath/bin/format.sh"]
            }
            commandLine inspectionPath
            if (!Os.isFamily(Os.FAMILY_WINDOWS)) {
                args = params
            }
        }
    }

    private void generateReport() {
        StringBuilder consoleReport = new StringBuilder()
        consoleReport.append("STATIC ANALYSIS RESULTS:")
        def count = 0

        def previousCount = count
        count = appendCpdErrors(count, new File("${project.buildDir}/reports/cpd.xml"))
        if (count - previousCount > 0) {
            consoleReport.append("\nCPD: FAILED (" + (count - previousCount) + " errors)")
        } else {
            consoleReport.append("\nCPD: PASSED")
        }

        previousCount = count
        count = appendKotlinErrors(count, new File("${project.buildDir}/reports/kotlin-detekt.xml"))
        if (count - previousCount > 0) {
            consoleReport.append("\nKotlin-detekt: FAILED (" + (count - previousCount) + " errors)")
        } else {
            consoleReport.append("\nKotlin-detekt: PASSED")
        }

        def pmdFile = new File("${project.buildDir}/reports/pmd.xml")
        def lintFile = new File("${project.buildDir}/reports/lint_report.xml")

        if (pmdFile.exists()) {
            previousCount = count
            count = appendPmdErrors(count, pmdFile)
            if (count - previousCount > 0) {
                consoleReport.append("\nPMD: FAILED (" + (count - previousCount) + " errors)")
            } else {
                consoleReport.append("\nPMD: PASSED")
            }
        }

        if (lintFile.exists()) {
            previousCount = count
            count = appendLintErrors(count,)
            if (count - previousCount > 0) {
                consoleReport.append("\nLint: FAILED (" + (count - previousCount) + " errors)")
            } else {
                consoleReport.append("\nLint: PASSED")
            }
        }

        if (count > 0) {
            consoleReport.append("\nOverall: FAILED (" + count + " errors)")
            throw new Exception(consoleReport.toString())
        } else {
            consoleReport.append("\nOverall: PASSED")
            println(consoleReport.toString())
        }
    }

    private void appendError(number, analyzer, file, line, errorId, errorLink, description) {
        println("$number. $analyzer : $description ($errorId)\n\tat $file: $line")
    }

    private int appendKotlinErrors(count, checkstyleFile) {
        def rootNode = new XmlParser().parse(checkstyleFile)
        for (def fileNode : rootNode.children()) {
            if (!fileNode.name().equals("file")) {
                continue
            }

            for (def errorNode : fileNode.children()) {
                if (!errorNode.name().equals("error")) {
                    continue
                }
                count++

                appendError(count, "Detekt", fileNode.attribute("name"), errorNode.attribute("line"), errorNode.attribute("source"), "", errorNode.attribute("message"))
            }
        }
        return count
    }

    private int appendCpdErrors(count, cpdFile) {
        def rootNode = new XmlParser().parse(cpdFile)
        for (def duplicationNode : rootNode.children()) {
            if (!duplicationNode.name().equals("duplication")) {
                continue
            }
            count++

            def duplicationIndex = 0

            String duplicationPoints = ""
            for (def filePointNode : duplicationNode.children()) {
                if (filePointNode.name().equals("file")) {
                    def file = filePointNode.attribute("path")
                    def line = filePointNode.attribute("line")
                    duplicationPoints += "\n " + file + ":" + line
                    duplicationIndex++
                }
            }
            println("$count CPD: code duplication $duplicationPoints")
        }
        return count
    }

    private int appendPmdErrors(count, pmdFile) {
        def rootNode = new XmlParser().parse(pmdFile)
        for (def fileNode : rootNode.children()) {
            if (!fileNode.name().equals("file")) {
                continue
            }

            for (def errorNode : fileNode.children()) {
                if (!errorNode.name().equals("violation")) {
                    continue
                }
                count++

                appendError(count, "PMD", fileNode.attribute("name"), errorNode.attribute("beginline"),
                        errorNode.attribute("rule").trim(), errorNode.attribute("externalInfoUrl").trim(), errorNode.text().trim())
            }
        }
        return count
    }

    private int appendLintErrors(count, lintFile) {
        def rootNode = new XmlParser().parse(lintFile)
        for (def issueNode : rootNode.children()) {
            if (!issueNode.name().equals("issue")
                    || !issueNode.attribute("severity").equals("Error")) {
                continue
            }
            for (def locationNode : issueNode.children()) {
                if (!locationNode.name().equals("location")) {
                    continue
                }
                count++
                appendError(count, "Lint", locationNode.attribute("file"), locationNode.attribute("line"),
                        issueNode.attribute("id"), issueNode.attribute("explanation"), issueNode.attribute("message"))
            }
        }
        return count
    }

    private String getCpdTask(sources) {
        def taskName = "cpd_${project.name}"
        def task = tasks.findByName(taskName)
        if (task == null) {
            task = tasks.create(taskName, tasks.findByName('cpdCheck').getClass().getSuperclass()) {
                minimumTokenCount = 60
                source = files(sources)
                ignoreFailures = true
                reports {
                    xml {
                        enabled = true
                        destination = file("${project.buildDir}/reports/cpd.xml")
                    }
                }
            }
        }
        return task.name
    }

    private String getPmdTask(sources) {
        def taskName = "pmd_${project.name}"
        def task = tasks.findByName(taskName)
        if (task == null) {
            task = tasks.create(taskName, Pmd) {
                pmdClasspath = configurations.pmd.asFileTree
                ruleSetFiles = files "$buildScriptsDir/pmd/rulesets/java/android.xml"
                ruleSets = []
                source files(sources)
                ignoreFailures = true
                reports {
                    html {
                        enabled = true
                        destination file("${project.buildDir}/reports/pmd.html")
                    }
                    xml {
                        enabled = true
                        destination file("${project.buildDir}/reports/pmd.xml")
                    }
                }
            }
        }
        return task.name
    }

    private String getLintTask(buildVariant) {
        def lintTaskName
        if (buildVariant != null) {
            lintTaskName = "lint${buildVariant.name.capitalize()}"
        } else {
            def lintDebugTask = tasks.matching { it.getName().contains("lint") && it.getName().contains("Debug") }.first()
            lintTaskName = lintDebugTask.getName()
        }
        android.lintOptions.abortOnError = false
        android.lintOptions.checkAllWarnings = true
        android.lintOptions.warningsAsErrors = false
        android.lintOptions.xmlReport = true
        android.lintOptions.xmlOutput = file "$project.buildDir/reports/lint_report.xml"
        android.lintOptions.htmlReport = false
        android.lintOptions.lintConfig = file "$buildScriptsDir/lint/lint.xml"
        return lintTaskName
    }


    private String getKotlinDetektTask() {
        // TODO add excludes from rootProject.extensions.findByName("staticAnalysisExcludes")
        return "detekt"
    }

}




