import groovy.util.XmlParser
import java.io.File

fun xmlParser(file: File) = XmlParser().parse(file)
