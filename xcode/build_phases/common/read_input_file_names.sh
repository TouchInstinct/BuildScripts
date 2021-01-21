#!/bin/sh

# Description:
#   Converts SCRIPT_INPUT_FILE_{N} or SCRIPT_INPUT_FILE_LIST_{N} variables to string that contains
#   list of file names splitted by given separator.
#
# Parameters:
#   $1 - separator to use.
#   $2 - default value to return if SCRIPT_INPUT_FILE_COUNT or SCRIPT_INPUT_FILE_LIST_COUNT is zero.
#
# Optional environment variables:
#   FILE_NAMES_SEPARATOR - separator to use.
#   DEFAULT_FILE_NAMES - default value if was found in environment variables.
#   SCRIPT_INPUT_FILE_COUNT - number of files listed in "Input files" section of build phase.
#   SCRIPT_INPUT_FILE_{N} - file path of specific input file at index.
#   SCRIPT_INPUT_FILE_LIST_COUNT - number of files listed in "Input File Lists" section of build phase.
#   SCRIPT_INPUT_FILE_LIST_{N} - file path to specifis xcfilelist file at index.
#
# Examples of usage:
#   read_input_file_names
#   read_input_file_names.sh " " path/to/project
#

has_input_files()
{
    [ ! -z "${SCRIPT_INPUT_FILE_COUNT}" ] && [ ${SCRIPT_INPUT_FILE_COUNT} -gt 0 ]
}

has_input_file_lists()
{
    [ ! -z "${SCRIPT_INPUT_FILE_LIST_COUNT}" ] && [ ${SCRIPT_INPUT_FILE_LIST_COUNT} -gt 0 ]
}

if [ -z "${FILE_NAMES_SEPARATOR}" ]; then
    if [ ! -z "${1}" ]; then
        FILE_NAMES_SEPARATOR=${1}
    else
        FILE_NAMES_SEPARATOR=" "
    fi
fi

if [ -z "${DEFAULT_FILE_NAMES}" ]; then
    if [ ! -z "${2}" ]; then
        DEFAULT_FILE_NAMES=${2}
    else
        DEFAULT_FILE_NAMES=""
    fi
fi

INPUT_FILE_NAMES=""

if has_input_files && has_input_file_lists; then
    >&2 echo "Passing Input Files and Input Files Lists is not supported!\nOnly Input Files will be used."
fi

if has_input_files && \
    [ ${SCRIPT_INPUT_FILE_COUNT} -gt 0 ]; then

    for i in `seq 0 $((${SCRIPT_INPUT_FILE_COUNT}-1))`
    do
        SCRIPT_INPUT_FILE_VARIABLE_NAME="SCRIPT_INPUT_FILE_${i}"
        SHELL_VARIABLE="\${${SCRIPT_INPUT_FILE_VARIABLE_NAME}}"
        RESOLVED_FILE_NAME=`envsubst <<< ${SHELL_VARIABLE}`
        INPUT_FILE_NAMES=${INPUT_FILE_NAMES}${FILE_NAMES_SEPARATOR}${RESOLVED_FILE_NAME}
    done

    FILE_NAMES_SEPARATOR_LENGTH=`awk '{ print length; }' <<< "${FILE_NAMES_SEPARATOR}"`

    if [ ${FILE_NAMES_SEPARATOR_LENGTH} -gt 0 ] && \
       [ ! -z "${INPUT_FILE_NAMES}" ]; then

        # remove separator prefix
        INPUT_FILE_NAMES=`cut -c${FILE_NAMES_SEPARATOR_LENGTH}- <<< ${INPUT_FILE_NAMES}`
    fi
elif has_input_file_lists; then
    for i in `seq 0 $((${SCRIPT_INPUT_FILE_LIST_COUNT}-1))`
    do
        SCRIPT_INPUT_FILE_LIST_VARIABLE_NAME="SCRIPT_INPUT_FILE_LIST_${i}"
        SHELL_VARIABLE="\${${SCRIPT_INPUT_FILE_LIST_VARIABLE_NAME}}"
        FILE_NAME=`envsubst <<< ${SHELL_VARIABLE}`
        RESOLVED_FILE_NAMES=`envsubst < ${FILE_NAME}`

        for INPUT_FILE_NAME in ${RESOLVED_FILE_NAMES}; do
            INPUT_FILE_NAMES=${INPUT_FILE_NAMES}${INPUT_FILE_NAME}${FILE_NAMES_SEPARATOR}
        done
    done
fi

if [ -z "${INPUT_FILE_NAMES}" ]; then
    echo ${DEFAULT_FILE_NAMES}
else
    echo ${INPUT_FILE_NAMES}
fi