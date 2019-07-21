import com.android.build.gradle.AppExtension
import com.android.build.gradle.api.ApplicationVariant
import groovy.lang.Closure
import groovy.util.Node
import groovy.util.XmlParser
import org.apache.tools.ant.taskdefs.condition.Os

val buildScriptsDir: String by rootProject.extra

apply(from = "$buildScriptsDir/gradle/commonStaticAnalysisLegacy.gradle")

buildscript {
    repositories {
        jcenter()
        google()
        maven("https://plugins.gradle.org/m2/")
        maven("https://maven.fabric.io/public")
    }
    dependencies {
        classpath("org.redundent:kotlin-xml-builder:1.5.1")
        classpath("com.android.tools.build:gradle:3.4.2")
        classpath(kotlin("gradle-plugin", version = "1.3.41"))
    }
}

apply(plugin = "checkstyle")
apply(plugin = "pmd")

configurations {
    "pngtastic"()
}

extra["getIdeaFormatTask"] = { isAndroidProject: Boolean, sources: List<String> ->
    val ideaPath = System.getenv("IDEA_HOME")
    if (ideaPath == null) {
        tasks.create((if (isAndroidProject) "android" else "server") + "donothing")
    } else {
        tasks.create((if (isAndroidProject) "android" else "server") + "IdeaFormat_${project.name}", Exec::class.java) {
            val params = mutableListOf("-r", "-mask", "*.java,*.kt,*.xml")
            for (source in sources) {
                params.add(source)
            }

            val inspectionPath = if (Os.isFamily(Os.FAMILY_WINDOWS)) {
                listOf("cmd", "/c", "\"$ideaPath\\bin\\format.bat\" ${params.joinToString(" ")}")
            } else {
                listOf("$ideaPath/bin/format.sh")
            }
            commandLine(inspectionPath)
            if (!Os.isFamily(Os.FAMILY_WINDOWS)) {
                setArgs(params as List<Any>)
            }
        }
    }
}

extra["getStaticAnalysisTaskNames"] = { isAndroidProject: Boolean, sources: List<String>, buildVariant: ApplicationVariant?, checkstyleEnabled: Boolean, pmdEnabled: Boolean ->
    val tasksNames = ArrayList<String>()
    try {
        tasksNames.add(getCpdTask(isAndroidProject, sources))
        tasksNames.add(getKotlinDetektTask())
        if (isAndroidProject) {
            if (checkstyleEnabled) {
                tasksNames.add(getCheckstyleTask(sources))
            }
            if (pmdEnabled) {
                tasksNames.add(getPmdTask(sources))
            }
            tasksNames.add(getLintTask(buildVariant))
        }
    } catch (exception: Exception) {
        println(exception.toString())
    }
    tasksNames
}

extra["generateReport"] = { isAndroidProject: Boolean ->
    val consoleReport = StringBuilder()
    consoleReport.append("STATIC ANALYSIS RESULTS:")
    var count = 0

    var previousCount = count
    count = appendCpdErrors(count, File("${project.buildDir}/reports/cpd.xml"))
    if (count - previousCount > 0) {
        consoleReport.append("\nCPD: FAILED (" + (count - previousCount) + " errors)")
    } else {
        consoleReport.append("\nCPD: PASSED")
    }

    previousCount = count
    count = appendKotlinErrors(count, File("${project.buildDir}/reports/kotlin-detekt.xml"))
    if (count - previousCount > 0) {
        consoleReport.append("\nKotlin-detekt: FAILED (" + (count - previousCount) + " errors)")
    } else {
        consoleReport.append("\nKotlin-detekt: PASSED")
    }

    if (isAndroidProject) {
        val checkstyleFile = File("${project.buildDir}/reports/checkstyle.xml")
        if (checkstyleFile.exists()) {
            previousCount = count
            count = appendCheckstyleErrors(count, checkstyleFile)
            if (count - previousCount > 0) {
                consoleReport.append("\nCheckstyle: FAILED (" + (count - previousCount) + " errors)")
            } else {
                consoleReport.append("\nCheckstyle: PASSED")
            }
        }

        val pmdFile = File("${project.buildDir}/reports/pmd.xml")
        if (pmdFile.exists()) {
            previousCount = count
            count = appendPmdErrors(count, pmdFile)
            if (count - previousCount > 0) {
                consoleReport.append("\nPMD: FAILED (" + (count - previousCount) + " errors)")
            } else {
                consoleReport.append("\nPMD: PASSED")
            }
        }

        previousCount = count
        count = appendLintErrors(count, File("${project.buildDir}/reports/lint_report.xml"))
        if (count - previousCount > 0) {
            consoleReport.append("\nLint: FAILED (" + (count - previousCount) + " errors)")
        } else {
            consoleReport.append("\nLint: PASSED")
        }
    }

    if (count > 0) {
        consoleReport.append("\nOverall: FAILED (" + count + " errors)")
        throw Exception(consoleReport.toString())
    } else {
        consoleReport.append("\nOverall: PASSED")
        println(consoleReport.toString())
    }
}

fun appendError(number: Any, analyzer: String, file: Any?, line: Any?, errorId: Any?, errorLink: Any?, description: Any?): Unit {
    println("$number. $analyzer : $description ($errorId)\n\tat $file: $line")
}

fun appendKotlinErrors(count: Int, checkstyleFile: File): Int {
    var newNode = count
    val rootNode = XmlParser().parse(checkstyleFile)
    for (fileNode in (rootNode.children() as List<Node>)) {
        if (fileNode.name() != "file") {
            continue
        }

        for (errorNode in (fileNode.children() as List<Node>)) {
            if (errorNode.name() != "error") {
                continue
            }
            newNode++

            appendError(
                    newNode,
                    "Detekt",
                    fileNode.attribute("name"),
                    errorNode.attribute("line"),
                    errorNode.attribute("source"),
                    "",
                    errorNode.attribute("message")
            )
        }
    }
    return newNode
}

fun appendCpdErrors(count: Int, cpdFile: File): Int {
    var newCount = count
    val rootNode = XmlParser().parse(cpdFile)
    for (duplicationNode in (rootNode.children() as List<Node>)) {
        if (duplicationNode.name() != "duplication") {
            continue
        }
        newCount++

        var duplicationIndex = 0

        var duplicationPoints = ""
        for (filePointNode in (duplicationNode.children() as List<Node>)) {
            if (filePointNode.name() == "file") {
                val file = filePointNode.attribute("path")
                val line = filePointNode.attribute("line")
                duplicationPoints += "\n $file:$line"
                duplicationIndex++
            }
        }
        println("$newCount CPD: code duplication $duplicationPoints")
    }
    return newCount
}

fun appendCheckstyleErrors(count: Int, checkstyleFile: File): Int {
    var newCount = count
    val rootNode = XmlParser().parse(checkstyleFile)
    for (fileNode in (rootNode.children() as List<Node>)) {
        if (fileNode.name() != "file") {
            continue
        }

        for (errorNode in (fileNode.children() as List<Node>)) {
            if (!errorNode.name().equals("error")) {
                continue
            }
            newCount++

            val error = errorNode.attribute("source")?.toString().orEmpty()
            val link = "http://checkstyle.sourceforge.net/apidocs/" + error.replace(".", "/") + ".html"
            appendError(
                    newCount,
                    "Checkstyle",
                    fileNode.attribute("name"),
                    errorNode.attribute("line"),
                    error,
                    link,
                    errorNode.attribute("message")
            )
        }
    }
    return newCount
}

fun appendPmdErrors(count: Int, pmdFile: File): Int {
    var newCount = count
    val rootNode = XmlParser().parse(pmdFile)
    for (fileNode in (rootNode.children() as List<Node>)) {
        if (fileNode.name() != "file") {
            continue
        }

        for (errorNode in (fileNode.children() as List<Node>)) {
            if (errorNode.name() != "violation") {
                continue
            }
            newCount++

            appendError(
                    newCount,
                    "PMD",
                    fileNode.attribute("name"),
                    errorNode.attribute("beginline"),
                    errorNode.attribute("rule")?.toString().orEmpty().trim(),
                    errorNode.attribute("externalInfoUrl")?.toString().orEmpty().trim(),
                    errorNode.text().orEmpty().trim()
            )
        }
    }
    return newCount
}

fun appendLintErrors(count: Int, lintFile: File): Int {
    var newCount = count
    val rootNode = XmlParser().parse(lintFile)
    for (issueNode in rootNode.children()) {
        if ((issueNode as Node).name() != "issue"
                || issueNode.attribute("severity") != "Error") {
            continue
        }
        for (locationNode in (issueNode.children() as List<Node>)) {
            if (locationNode.name() != "location") {
                continue
            }
            newCount++
            appendError(
                    newCount,
                    "Lint",
                    locationNode.attribute("file"),
                    locationNode.attribute("line"),
                    issueNode.attribute("id"),
                    issueNode.attribute("explanation"),
                    issueNode.attribute("message")
            )
        }
    }
    return newCount
}

fun getCpdTask(isAndroidProject: Boolean, sources: List<String>): String =
        (extra["getCpdTask"] as Closure<String>)(isAndroidProject, sources)

fun getPmdTask(sources: List<String>): String {
    val taskName = "pmd_${project.name}"
    var task = tasks.findByName(taskName)
    if (task == null) {
        task = tasks.create(taskName, Pmd::class.java) {
            pmdClasspath = configurations["pmd"].asFileTree
            ruleSetFiles = files("$buildScriptsDir/pmd/rulesets/java/android.xml")
            ruleSets = emptyList()
            source = files(sources).asFileTree
            ignoreFailures = true
            reports {
                html.isEnabled = true
                html.destination = file("${project.buildDir}/reports/pmd.html")

                xml.isEnabled = true
                xml.destination = file("${project.buildDir}/reports/pmd.xml")
            }
        }
    }
    return task!!.name
}

fun getLintTask(buildVariant: ApplicationVariant?): String =
        (extra["getLintTask"] as Closure<String>)(buildVariant)

fun getCheckstyleTask(sources: List<String>): String {
    val taskName = "checkstyle_${project.name}"
    var task = tasks.findByName(taskName)
    if (task == null) {
        val compileReleaseTask = tasks.matching {
            it.name.contains("compile")
                    && it.name.contains("Release")
                    && it.name.contains("Java") &&
                    !it.name.contains("UnitTest")
        }.last()
        task = tasks.create(taskName, Checkstyle::class.java) {
            ignoreFailures = true
            isShowViolations = false
            source = files(sources).asFileTree
            configFile = file("$buildScriptsDir/checkstyle/configuration/touchin_checkstyle.xml")
            checkstyleClasspath = configurations["checkstyle"].asFileTree
            classpath = files(System.getenv("ANDROID_HOME") + "/platforms/" + (extensions["android"] as AppExtension).compileSdkVersion + "/android.jar") +
                    files(System.getProperties()["java.home"].toString() + "/lib/rt.jar") +
                    files((compileReleaseTask.extra["classpath"] as String))
            reports {
                xml.isEnabled = true
                xml.destination = file("${project.buildDir}/reports/checkstyle.xml")
            }
        }
    }
    return task!!.name
}

fun getKotlinDetektTask() = "detekt"

task("optimizePng") {
    doFirst {
        val jarArgs = ArrayList<String>()
        jarArgs.add(configurations["pngtastic"].asPath)
        val relatedPathIndex = "$rootDir".length + 1
        for (file in fileTree("dir" to "$rootDir", "include" to "**/src/**/res/drawable**/*.png")) {
            jarArgs.add(file.absolutePath.substring(relatedPathIndex))
        }
        for (file in fileTree("dir" to "$rootDir", "include" to "**/src/**/res/mipmap**/*.png")) {
            jarArgs.add(file.absolutePath.substring(relatedPathIndex))
        }
        javaexec { main = "-jar"; args = jarArgs; workingDir = file("${rootDir}") }
    }
}

dependencies {
    "pmd"("net.sourceforge.pmd:pmd-core:5.5.3")

    "checkstyle"("ru.touchin:checkstyle:7.6.2-fork")

    "pngtastic"("com.github.depsypher:pngtastic:1.2")
}
