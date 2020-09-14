# source: https://github.com/iKenndac/verify-string-files

readonly SOURCES_DIR=${1:-${PROJECT_DIR}} # first argument or PROJECT_DIR
readonly LOCALIZATION_PATH="${PRODUCT_NAME}/Resources/Localization/Base.lproj/Localizable.strings"
readonly CHECK_SCRIPT="${SOURCES_DIR}/build-scripts/xcode/build_phases/common/localization_check"

if [ "${CONFIGURATION}" = "DEBUG" ]; then
	${SOURCES_DIR} -master ${LOCALIZATION_PATH} -warning-level warning
else
	${CHECK_SCRIPT} -master ${LOCALIZATION_PATH}
fi
