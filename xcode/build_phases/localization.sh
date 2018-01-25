LOCALIZATION_PATH="${PROJECT_NAME}/Resources/Localization"
STRINGS_FOLDER="common/strings"

if ! [ -e ${LOCALIZATION_PATH} ]; then
	echo "${PROJECT_DIR}/${LOCALIZATION_PATH} path does not exist. Add these folders and try again."
	exit 1
fi

if ! [ -e "${PROJECT_DIR}/${STRINGS_FOLDER}" ]; then
	echo "${PROJECT_DIR}/${STRINGS_FOLDER} path does not exist. Submodule with strings should be named common and contain strings folder."
	exit 1
fi

php build-scripts/xcode/aux_scripts/import_strings.php ${PROJECT_NAME} ${STRINGS_FOLDER}
