# Description:
#   Validates code for copy-paste, prints results to standard output and report file.
#
# Parameters:
#   $1 $2 $3 $n - folders to exclude from code checking.
#
# Required environment variables:
#   PROJECT_DIR - project directory.
#
# Optional environment variables:
#   SCRIPT_INPUT_FILE_COUNT - number of files listed in "Input files" of build phase.
#   SCRIPT_INPUT_FILE_{N} - file path to directory that should be checked.
#
# Modified files:
#   ${PROJECT_DIR}/code-quality-reports/CPDLog.txt - check report.
#   ${PROJECT_DIR}/code-quality-reports/CPDCommit - last checked commit.
#
# Example of usage:
#   copy_paste_detection.sh Generated Localization Pods
#

readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1

read_input_file_names()
{
    local -r DEFAULT_VALUE=${1}

    local INPUT_FILE_NAMES=""

    if [ "${SCRIPT_INPUT_FILE_COUNT}" -gt 0 ] ; then
        for i in `seq 0 $((${SCRIPT_INPUT_FILE_COUNT}-1))`
        do
            local SCRIPT_INPUT_FILE_VARIABLE_NAME="SCRIPT_INPUT_FILE_${i}"
            local COMMAND="echo \${${SCRIPT_INPUT_FILE_VARIABLE_NAME}}"
            local INPUT_FILE_NAME=`eval ${COMMAND}`
            INPUT_FILE_NAMES=${INPUT_FILE_NAMES}${INPUT_FILE_NAME}" "
        done

        echo ${INPUT_FILE_NAMES}
    else
        echo ${DEFAULT_VALUE}
    fi
}

is_nothing_changed_since_last_check()
{
    local -r COMMIT_FILE_PATH=${1}
    local -r LAST_LINTED_COMMIT=`cat ${COMMIT_FILE_PATH}` || ""

    local -r CURRENT_COMMIT=${2}

    if [[ "${CURRENT_GIT_COMMIT}" = "${LAST_LINTED_COMMIT}" ]]; then
        if git diff --quiet --exit-code; then
            echo "Commit your changes and build again."
        else
            echo "Nothing was changed since ${LAST_LINTED_COMMIT}. Skipping code checking."
        fi

        return ${EXIT_SUCCESS}
    else
        return ${EXIT_FAILURE}
    fi
}

if which pmd >/dev/null; then
    readonly REPORTS_DIR="${PROJECT_DIR}/code-quality-reports"

    readonly CPD_COMMIT_FILE_PATH="${REPORTS_DIR}/CPDCommit"

    readonly CURRENT_GIT_COMMIT=`git rev-parse --verify HEAD`

    if is_nothing_changed_since_last_check ${CPD_COMMIT_FILE_PATH} ${CURRENT_GIT_COMMIT}; then
        exit ${EXIT_SUCCESS}
    fi

    readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

    readonly SOURCES_DIRS=`read_input_file_names ${PROJECT_DIR}`

    readonly COMMAND_LINE_ARGUMENTS=$@

    FOLDERS_TO_EXLUDE=""

    for argument in ${COMMAND_LINE_ARGUMENTS}
    do
      FOLDERS_TO_EXLUDE=${FOLDERS_TO_EXLUDE}"-or -name ${argument} "
    done

    FOLDERS_TO_EXLUDE=`echo ${FOLDERS_TO_EXLUDE} | cut -c5-` # remove first "-or"

    readonly FILES_TO_EXCLUDE=`find ${PROJECT_DIR} -type d ${FOLDERS_TO_EXLUDE} | paste -sd " " -`

    mkdir -p ${REPORTS_DIR}

    pmd cpd --files ${SOURCES_DIRS} --exclude ${FILES_TO_EXCLUDE} --minimum-tokens 50 --language swift --encoding UTF-8 --format net.sourceforge.pmd.cpd.XMLRenderer --failOnViolation true > ${REPORTS_DIR}/cpd-output.xml

    php ${SCRIPT_DIR}/../aux_scripts/cpd_script.php ${REPORTS_DIR}/cpd-output.xml | tee ${REPORTS_DIR}/CPDLog.txt

    # Make paths relative to PROJECT_DIR, so different developers won't rewrite entire file
    readonly SED_REPLACEMENT_STRING=$(echo ${PROJECT_DIR} | sed "s/\//\\\\\//g")

    sed -i '' "s/${SED_REPLACEMENT_STRING}//g" "${REPORTS_DIR}/CPDLog.txt"

    echo ${CURRENT_GIT_COMMIT} > ${CPD_COMMIT_FILE_PATH}
else
    echo "warning: pmd not installed, install using 'brew install pmd'"

    exit ${EXIT_FAILURE}
fi
