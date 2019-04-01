import groovy.json.JsonSlurper
import groovy.xml.MarkupBuilder
import org.gradle.api.internal.plugins.DefaultExtraPropertiesExtension

task("stringGenerator") {
//    val languageMap: Map<String, String>? = android.extensions.findByName("languageMap")

    println(extra.properties)
//    println(android.ext)
//    generate(languageMap)
    println("Strings generated!")
}

//private def generate(Map<String, String> sources) {
//    if (sources == null || sources.isEmpty()) {
//        throw new IOException("languageMap can't be null or empty")
//    }
//    Map jsonMap = getJsonsMap(sources)
//    def diffs = calcDiffs(jsonMap)
//    if (!diffs.isEmpty()) {
//        printDiffs(diffs)
//        throw new IllegalStateException("Strings source can't be different")
//    }
//    def defaultLang = getDefaultLangKey(sources)
//    jsonMap.forEach { key, json ->
//
//        def sw = new StringWriter()
//        def xml = new MarkupBuilder(sw)
//
//        xml.setDoubleQuotes(true)
//        xml.mkp.xmlDeclaration(version: "1.0", encoding: "utf-8")
//        xml.resources() {
//            json.each {
//                k, v ->
//                    string(name: "${k}", formatted: "false", "${v}".replace('\n', '\\n'))
//            }
//        }
//
//        def stringsFile = getFile(key, key == defaultLang)
//        stringsFile.write(sw.toString(), "UTF-8")
//    }
//}
//
//private printDiffs(Map<?, ?> diffs) {
//    def diffLog = new StringBuilder()
//    diffs.forEach { k, v ->
//        if (v.size() > 0) {
//            diffLog.append("For $k was missed string keys: ${v.size()}\n")
//            v.forEach {
//                diffLog.append("\tString key: $it\n")
//            }
//        }
//    }
//    println(diffLog.toString())
//}
//
//private static def calcDiffs(Map<String, Object> jsonsMap) {
//    if (jsonsMap.size() == 1) {
//        return [:]
//    }
//    def keys = jsonsMap.collectEntries {
//        [(it.key): (it.value).keySet() as List]
//    }
//    def inclusive = keys.get(keys.keySet().first())
//    def diffs = keys.collectEntries {
//        [(it.key): inclusive - it.value.intersect(inclusive)]
//    }.findAll { it.value.size() > 0 }
//    return diffs
//}
//
//private static Map<String, Object> getJsonsMap(Map sources) {
//    return sources.collectEntries {
//        [(it.key): new JsonSlurper().parseText(new File(it.value).text)]
//    }
//}
//
//private static File getFile(String key, boolean defaultLang) {
//    if (defaultLang) {
//        return new File("app/src/main/res/values/strings.xml")
//    } else {
//        def directory = new File("app/src/main/res/values-$key")
//        if (!directory.exists()) {
//            directory.mkdir()
//        }
//        return new File("app/src/main/res/values-$key/strings.xml")
//    }
//}
//
//private static String getDefaultLangKey(Map<String, String> sources) {
//    def defaultLanguage = sources.find { it.value.contains("default") }
//    if (defaultLanguage != null) {
//        return defaultLanguage.key
//    } else {
//        throw new IOException("Can't find default language")
//    }
//
//}
