readonly SOURCES_DIR=${1:-${PROJECT_DIR}} # first argument or PROJECT_DIR
readonly UNUSED_RESOURCES_SCRIPT=${2:-${PROJECT_DIR}/build-scripts/xcode/build_phases/common/unused_resources} # second argument set check script path
readonly REPORTS_DIR=${PROJECT_DIR}/code-quality-reports
readonly FILES_TO_EXCLUDE=`find ${SOURCES_DIR} -type d -name Localization -or -name Generated -or -name Carthage -or -name Pods | paste -sd " " -`

mkdir ${REPORTS_DIR}

${UNUSED_RESOURCES_SCRIPT} --project ${SOURCES_DIR} --exclude ${FILES_TO_EXCLUDE} --resource-extensions 'imageset jpg png gif pdf txt' > ${REPORTS_DIR}/Unused_resources_log.txt
