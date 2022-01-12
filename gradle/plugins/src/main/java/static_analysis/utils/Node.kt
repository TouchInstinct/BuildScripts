package static_analysis.utils

import groovy.util.Node

fun Node.typedChildren() = children() as List<Node>
