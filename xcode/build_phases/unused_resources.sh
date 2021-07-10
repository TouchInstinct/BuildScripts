readonly SOURCES_DIR=${1:-${PROJECT_DIR}/${PRODUCT_NAME}} # first argument set product dir
readonly UNUSED_RESOURCES_SCRIPT=${2:-${PROJECT_DIR}/build-scripts/xcode/build_phases/common/unused_resources} # second argument set script path
readonly REPORTS_DIR=${PROJECT_DIR}/code-quality-reports
readonly FILES_TO_EXCLUDE=`find ${SOURCES_DIR} -type d -name Localization -or -name Generated | paste -sd " " -`

mkdir ${REPORTS_DIR}

${UNUSED_RESOURCES_SCRIPT} --project ${SOURCES_DIR} --exclude ${FILES_TO_EXCLUDE} --action "l" > ${REPORTS_DIR}/Unused_resources_log.txt
