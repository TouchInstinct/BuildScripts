# source: https://github.com/iKenndac/verify-string-files

readonly SOURCES_DIR=${1:-${PROJECT_DIR}} # first argument or PROJECT_DIR

if [ "${CONFIGURATION}" = "DEBUG" ]; then
	${SOURCES_DIR}/build-scripts/xcode/build_phases/common/localization_check -master ${SOURCES_DIR}/Resources/Localization/Base.lproj/Localizable.strings -warning-level warning
else
	${SOURCES_DIR}/build-scripts/xcode/build_phases/common/localization_check -master ${SOURCES_DIR}/Resources/Localization/Base.lproj/Localizable.strings
fi
