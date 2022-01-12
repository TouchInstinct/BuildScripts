readonly ARGUMENTS=("$@")
readonly IGNORED_FILES=$(IFS=, ; echo "${ARGUMENTS[*]}")
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ruby ${SCRIPT_DIR}/Unused.rb --config ${SCRIPT_DIR}/../UnusedConfig.yml --exclude ${IGNORED_FILES}
