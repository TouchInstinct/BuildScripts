# source: https://github.com/iKenndac/verify-string-files

# first argument set base localization strings path
readonly LOCALIZATION_PATH=${1:-${PRODUCT_NAME}/Resources/Localization/Base.lproj/Localizable.strings}

# second argument set check script path
readonly CHECK_SCRIPT=${2:-${PROJECT_DIR}/build-scripts/xcode/build_phases/common/localization_check}

${CHECK_SCRIPT} -master ${LOCALIZATION_PATH}
