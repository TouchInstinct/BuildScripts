# Input paths
readonly BUILD_SETTINGS_FILE_PATH=${1:-${PROJECT_DIR}/common/build_settings.yaml}
readonly FEATURES_ENUM_FILE_PATH=${2:-${PROJECT_DIR}/${PRODUCT_NAME}/Resources/Features/Feature.swift}

# Features enunm generator script
readonly CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
readonly GENERATOR_SCRIPT=${CURRENT_DIR}/features_generator.rb

if ! [ -e ${BUILD_SETTINGS_FILE_PATH} ]; then
	echo "File ${BUILD_SETTINGS_FILE_PATH} does not exist. Add this file and try again."
	exit 1
fi

if ! [ -e ${FEATURES_ENUM_FILE_PATH} ]; then
	echo "File ${FEATURES_ENUM_FILE_PATH} does not exist. Add this file and try again."
	exit 1
fi

ruby ${GENERATOR_SCRIPT} ${BUILD_SETTINGS_FILE_PATH} ${FEATURES_ENUM_FILE_PATH}