arguments=("$@")
ignored_files=$(IFS=, ; echo "${arguments[*]}")

ruby ${PROJECT_DIR}/build-scripts/xcode/build_phases/Unused.rb --config ${PROJECT_DIR}/build-scripts/xcode/UnusedConfig.yml --exclude ${ignored_files}
