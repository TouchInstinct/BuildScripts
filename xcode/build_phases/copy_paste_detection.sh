#!/bin/sh

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
#   REFACTORING_MODE - special bool flag for unconditional code checking.
#
# Modified files:
#   ${PROJECT_DIR}/code-quality-reports/CPDLog.txt - check report.
#   ${PROJECT_DIR}/code-quality-reports/CPDCommit - last checked commit.
#
# Example of usage:
#   runner.sh copy_paste_detection.sh Generated Localization Pods
#

is_refactoring_mode()
{
    if [ -z "${REFACTORING_MODE}" ]; then
        return ${FALSE}
    fi

    local -r STR_MODE=`tr "[:upper:]" "[:lower:]" <<< ${REFACTORING_MODE}`

    if [ ${STR_MODE} == "yes" ] || [ ${STR_MODE} == "true" ] || [ ${STR_MODE} == "1" ]; then
        return ${TRUE}
    fi

    return ${FALSE}
}

is_nothing_changed_since_last_check()
{
    if is_refactoring_mode; then
        echo "Refactoring mode detected. Skipping commits comparison."
        return ${EXIT_FAILURE}
    fi

    if [ -z "${COMMIT_FILE_PATH}" ]; then
        if [ ! -z "${1}" ]; then
            local -r COMMIT_FILE_PATH=${1}
        else
            echo "COMMIT_FILE_PATH should be defined or passed as first argument!"
            return ${EXIT_FAILURE}
        fi
    fi

    if [ -z "${CURRENT_COMMIT}" ]; then
        if [ ! -z "${2}" ]; then
            local -r CURRENT_COMMIT=${2}
        else
            local -r CURRENT_COMMIT=`git rev-parse --verify HEAD`
        fi
    fi

    local -r LAST_CHECKED_COMMIT=`cat ${COMMIT_FILE_PATH}` || ""

    if [ ${CURRENT_COMMIT} = ${LAST_CHECKED_COMMIT} ]; then
        if git diff --quiet --exit-code; then
            echo "Commit your changes and run script again."
        else
            echo "Nothing was changed since ${LAST_CHECKED_COMMIT}. Skipping."
        fi

        return ${EXIT_SUCCESS}
    else
        return ${EXIT_FAILURE}
    fi
}

record_current_commit()
{
    if is_refactoring_mode; then
        echo "Refactoring mode detected. Commit won't be recorder."
        exit ${EXIT_SUCCESS}
    fi

    if [ -v "${CURRENT_COMMIT}" ]; then
        if [ ! -v "${1}" ]; then
            local -r CURRENT_COMMIT=${1}
        else
            local -r CURRENT_COMMIT=`git rev-parse --verify HEAD`
        fi
    fi

    if [ -v "${COMMIT_FILE_PATH}" ]; then
        if [ ! -v "${2}" ]; then
            local -r COMMIT_FILE_PATH=${2}
        else
            echo "COMMIT_FILE_PATH should be defined or passed as second argument!"
            return ${EXIT_FAILURE}
        fi
    fi

    echo ${CURRENT_COMMIT} > ${COMMIT_FILE_PATH}
}

if which pmd >/dev/null; then
    readonly REPORTS_DIR="${PROJECT_DIR}/code-quality-reports"

    readonly COMMIT_FILE_PATH="${REPORTS_DIR}/CPDCommit"

    readonly CURRENT_COMMIT=`git rev-parse --verify HEAD`

    if is_nothing_changed_since_last_check; then
        exit ${EXIT_SUCCESS}
    fi

    readonly SOURCES_DIRS=`. ${SCRIPT_DIR}/common/read_input_file_names.sh " " ${PROJECT_DIR}`

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

    record_current_commit
else
    echo "warning: pmd not installed, install using 'brew install pmd'"

    exit ${EXIT_FAILURE}
fi
