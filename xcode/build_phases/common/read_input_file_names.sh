#!/bin/sh

# Description:
#   Converts SCRIPT_INPUT_FILE_{N} variables to single string using passed separator.
#
# Parameters:
#   $1 - separator to use.
#   $2 - default value to return if SCRIPT_INPUT_FILE_COUNT is zero.
#
# Optional environment variables:
#   FILE_NAMES_SEPARATOR - number of files listed in "Input files" of build phase.
#   DEFAULT_FILE_NAMES - file path to directory that should be checked.
#
# Examples of usage:
#   read_input_file_names
#   read_input_file_names.sh " " path/to/project
#

if [ -z "${FILE_NAMES_SEPARATOR}" ]; then
    if [ ! -z "${1}" ]; then
        FILE_NAMES_SEPARATOR=${1}
    else
        FILE_NAMES_SEPARATOR=""
    fi
fi

if [ -z "${DEFAULT_FILE_NAMES}" ]; then
    if [ ! -z "${2}" ]; then
        DEFAULT_FILE_NAMES=${2}
    else
        DEFAULT_FILE_NAMES=""
    fi
fi

if [ "${SCRIPT_INPUT_FILE_COUNT}" -gt 0 ] ; then
    INPUT_FILE_NAMES=""

    for i in `seq 0 $((${SCRIPT_INPUT_FILE_COUNT}-1))`
    do
        SCRIPT_INPUT_FILE_VARIABLE_NAME="SCRIPT_INPUT_FILE_${i}"
        COMMAND="echo \${${SCRIPT_INPUT_FILE_VARIABLE_NAME}}"
        INPUT_FILE_NAME=`eval ${COMMAND}`
        INPUT_FILE_NAMES=${INPUT_FILE_NAMES}${INPUT_FILE_NAME}${FILE_NAMES_SEPARATOR}
    done

    FILE_NAMES_SEPARATOR_LENGTH=`awk '{ print length; }' <<< ${FILE_NAMES_SEPARATOR}`
    INPUT_FILE_NAMES_LENGTH=`awk '{ print length; }' <<< ${INPUT_FILE_NAMES}`
    INPUT_FILE_NAMES_TRIMMED_LENGTH=$((INPUT_FILE_NAMES_LENGTH - FILE_NAMES_SEPARATOR_LENGTH))

    # remove separator suffix
    echo ${INPUT_FILE_NAMES} | cut -c1-${INPUT_FILE_NAMES_TRIMMED_LENGTH}
else
    echo ${DEFAULT_VALUE}
fi