# source: https://github.com/iKenndac/verify-string-files

SOURCES_DIR=${1:-${TARGET_NAME}} # first argument or TARGET_NAME

if [ "${CONFIGURATION}" = "DEBUG" ]; then
	${SOURCES_DIR}/build-scripts/xcode/build_phases/common/localization_check -master ${SOURCES_DIR}/Resources/Base.lproj/Localizable.strings -warning-level warning
else
	${SOURCES_DIR}/build-scripts/xcode/build_phases/common/localization_check -master ${SOURCES_DIR}/Resources/Base.lproj/Localizable.strings
fi
