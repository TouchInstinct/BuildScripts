import com.google.gson.JsonObject
import com.google.gson.JsonParser
import org.redundent.kotlin.xml.PrintOptions
import org.redundent.kotlin.xml.xml

buildscript {
    repositories {
        jcenter()
    }
    dependencies {
        classpath("org.redundent:kotlin-xml-builder:1.5.1")
        classpath("com.google.code.gson:gson:2.8.5")
    }
}

task("stringGenerator") {
    val languageMap: Map<String, String>? by rootProject.extra
    generate(languageMap)
    println("Strings generated!")
}

fun generate(sources: Map<String, String>?) {
    if (sources == null || sources.isEmpty()) {
        throw java.io.IOException("languageMap can't be null or empty")
    }
    val jsonMap = getJsonsMap(sources)
    val diffs = calcDiffs(jsonMap)
    if (diffs.isNotEmpty()) {
        printDiffs(diffs)
        throw IllegalStateException("Strings source can't be different")
    }
    val defaultLang = getDefaultLangKey(sources)
    jsonMap.forEach { (key, json) ->
        val xmlString = xml("resources") {
            includeXmlProlog = true
            json.entrySet().forEach {
                "string" {
                    attribute("name", it.key)
                    attribute("formatted", "false")
                    -it.value.asString.replace("\n", "\\n")
                }
            }
        }

        val stringsFile = getFile(key, key == defaultLang)
        stringsFile.writeText(xmlString.toString(PrintOptions(singleLineTextElements = true)))
    }
}

fun printDiffs(diffs: Map<String, Set<String>>) {
    val diffLog = StringBuilder()
    diffs.forEach { (key, value) ->
        if (value.isNotEmpty()) {
            diffLog.append("For $key was missed string keys: ${value.size}\n")
            value.forEach {
                diffLog.append("\tString key: $it\n")
            }
        }
    }
    println(diffLog.toString())
}

fun calcDiffs(jsonsMap: Map<String, JsonObject>): Map<String, Set<String>> {
    if (jsonsMap.size == 1) {
        return emptyMap()
    }
    val keys = jsonsMap.mapValues {
        it.value.keySet().toList()
    }
    val inclusive = keys[keys.keys.first()]!!.toSet()
    return keys.mapValues {
        inclusive - it.value.intersect(inclusive)
    }.filter { it.value.isNotEmpty() }
}

fun getJsonsMap(sources: Map<String, String>): Map<String, JsonObject> {
    return sources.mapValues {
        JsonParser().parse(File(it.value).readText()).asJsonObject
    }
}

fun getFile(key: String, defaultLang: Boolean): File {
    if (defaultLang) {
        return File("app/src/main/res/values/strings.xml")
    } else {
        val directory = File("app/src/main/res/values-$key")
        if (!directory.exists()) {
            directory.mkdir()
        }
        return File("app/src/main/res/values-$key/strings.xml")
    }
}

fun getDefaultLangKey(sources: Map<String, String>): String {
    val defaultLanguage = sources
            .filter { it.value.contains("default") }
            .iterator().run {
                if (hasNext()) next() else null
            }
    if (defaultLanguage != null) {
        return defaultLanguage.key
    } else {
        throw java.io.IOException("Can't find default language")
    }
}
