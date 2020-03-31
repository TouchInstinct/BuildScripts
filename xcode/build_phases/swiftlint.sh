SOURCES_DIR=${1:-${TARGET_NAME}} # first argument or TARGET_NAME
${PODS_ROOT}/SwiftLint/swiftlint autocorrect --path ${SOURCES_DIR} --config ${PROJECT_DIR}/build-scripts/xcode/.swiftlint.yml && ${PODS_ROOT}/SwiftLint/swiftlint --path ${SOURCES_DIR} --config ${PROJECT_DIR}/build-scripts/xcode/.swiftlint.yml
