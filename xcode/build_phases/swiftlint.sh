#!/bin/sh

# Description:
#   Runs swiftlint with selected or default config file.
#
# Parameters:
#   $1 - path to swiftlint executable.
#   $2 - path to swiftlint config.
#
# Required environment variables:
#   SCRIPT_DIR - directory of current script.
#   SRCROOT - project directory.
#   PODS_ROOT - cocoapods installation directory (eg. ${SRCROOT}/Pods).
#
# Optional environment variables:
#   SWIFTLINT_EXECUTABLE - path to swiftlint executable.
#   SWIFTLINT_CONFIG_PATH - path to swiftlint config.
#   SCRIPT_INPUT_FILE_COUNT - number of files listed in "Input files" of build phase.
#   SCRIPT_INPUT_FILE_{N} - file path to directory that should be checked.
#
# Example of usage:
#   swiftlint.sh
#   swiftlint.sh Pods/Swiftlint/swiftlint build-scripts/xcode/.swiftlint.yml
#

readonly SOURCES_DIRS=`. ${SCRIPT_DIR}/common/read_input_file_names.sh "\n" ${SRCROOT}`

if [ -z "${SWIFTLINT_EXECUTABLE}" ]; then
    if [ ! -z "${1}" ]; then
        readonly SWIFTLINT_EXECUTABLE=${1}
    else
        readonly SWIFTLINT_EXECUTABLE=${PODS_ROOT}/SwiftLint/swiftlint
    fi
fi

if [ -z "${SWIFTLINT_CONFIG_PATH}" ]; then
    if [ ! -z "${2}" ]; then
        readonly SWIFTLINT_CONFIG_PATH=${2}
    else
        readonly SWIFTLINT_CONFIG_PATH=${SCRIPT_DIR}/../.swiftlint.yml
    fi
fi

for SOURCE_DIR in ${SOURCES_DIRS}; do
    ${SWIFTLINT_EXECUTABLE} autocorrect --path ${SOURCE_DIR} --config ${SWIFTLINT_CONFIG_PATH}
    ${SWIFTLINT_EXECUTABLE} --path ${SOURCE_DIR} --config ${SWIFTLINT_CONFIG_PATH}
done
