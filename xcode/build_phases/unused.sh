readonly ARGUMENTS=("$@")
readonly IGNORED_FILES=$(IFS=, ; echo "${ARGUMENTS[*]}")
readonly CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ruby ${CURRENT_DIR}/Unused.rb --config ${CURRENT_DIR}/../UnusedConfig.yml --exclude ${IGNORED_FILES}
