package static_analysis.utils

import groovy.util.Node
import groovy.util.XmlParser
import org.gradle.api.Project
import org.gradle.api.file.FileTree
import java.io.File

fun Node.typedChildren() = children() as List<Node>

fun xmlParser(file: File) = XmlParser().parse(file)

fun Project.getSources(excludes: String): FileTree = files(
        project
                .rootProject
                .subprojects
                .filter { subproject -> subproject.subprojects.isEmpty() && !excludes.contains(subproject.path) }
                .map { subproject -> subproject.file("${subproject.projectDir.path}/src/main") }
                .filter { it.exists() && it.isDirectory }
                .flatMap { srcDir ->
                    srcDir
                            .listFiles()
                            .orEmpty()
                            .flatMap {
                                listOf(
                                        File(srcDir.path, "java"),
                                        File(srcDir.path, "kotlin")
                                )
                            }
                }
                .filter { it.exists() && it.isDirectory }
                .map { it.path }
).asFileTree
