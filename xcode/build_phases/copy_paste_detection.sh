#!/bin/sh

# Description:
#   Validates code for copy-paste, prints results to standard output and report file.
#
# Parameters:
#   $1 $2 $3 $n - folders to exclude from code checking.
#
# Required environment variables:
#   PROJECT_DIR - project directory.
#   SCRIPT_DIR - directory of current script.
#
# Optional environment variables:
#   SCRIPT_INPUT_FILE_COUNT - number of files listed in "Input files" of build phase.
#   SCRIPT_INPUT_FILE_{N} - file path to directory that should be checked.
#
# Modified files:
#   ${PROJECT_DIR}/code-quality-reports/CPDLog.txt - check report.
#
# Example of usage:
#   runner.sh copy_paste_detection.sh Generated Localization Pods
#

readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1

. ${SCRIPT_DIR}/../aux_scripts/install_env.sh pmd

if which pmd >/dev/null; then
    readonly REPORTS_DIR="${PROJECT_DIR}/code-quality-reports"

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
else
    echo "warning: pmd not installed, install using 'brew install pmd'"

    exit ${EXIT_FAILURE}
fi
