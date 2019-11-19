LOCALIZATION_PATH="${PRODUCT_NAME}/Resources/Localization"
#first argument set strings folder path
STRINGS_FOLDER=${1:-"common/strings"}

if ! [ -e ${LOCALIZATION_PATH} ]; then
	echo "${PROJECT_DIR}/${LOCALIZATION_PATH} path does not exist. Add these folders and try again."
	exit 1
fi

if ! [ -e "${PROJECT_DIR}/${STRINGS_FOLDER}" ]; then
	echo "${PROJECT_DIR}/${STRINGS_FOLDER} path does not exist. Submodule with strings should be named common and contain strings folder."
	exit 1
fi

#second argument set strings script path
php ${2:-build-scripts/xcode/aux_scripts/import_strings.php} ${PRODUCT_NAME} ${STRINGS_FOLDER}
