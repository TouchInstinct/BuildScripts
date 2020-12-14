readonly build_settings_file_path="${PROJECT_DIR}/common/build_settings.yaml"
readonly generated_file_path="${PROJECT_DIR}/${PRODUCT_NAME}/Resources/Features/FeatureToggles.swift"

if ! [ -e ${build_settings_file_path} ]; then
	echo "File ${PROJECT_DIR}/common/build_settings.yaml does not exist. Add this file and try again."
	exit 1
fi

if ! [ -e ${generated_file_path} ]; then
	echo "File ${PROJECT_DIR}/${PRODUCT_NAME}/Resources/Features/FeatureToggles.swift does not exist. Add this file and try again."
	exit 1
fi

ruby ${PROJECT_DIR}/build-scripts/xcode/build_phases/features_generator/features_generator.rb ${build_settings_file_path} ${generated_file_path}
