#!/bin/sh

# Description:
#   Generates Localizeable.strings and String+Localization.swift files.
#
# Parameters:
#   $1 - path to strings folder containing json files.
#   $2 - path to Localization folder (output).
#   $3 - Bundle for localization. Default is `.main`.
#
# Required environment variables:
#   SCRIPT_DIR - directory of current script.
#
# Optional environment variables:
#   PRODUCT_NAME - product name to produce path to localization folder (output).
#
# Examples of usage:
#   . localization.sh
#   . localization.sh common/strings Resources/Localization/ .main
#

readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1

. ${SCRIPT_DIR}/../aux_scripts/install_env.sh php

STRINGS_FOLDER=${1:-"common/strings"}
LOCALIZATION_PATH=${2:-"${PRODUCT_NAME}/Resources/Localization/"}
BUNDLE=${3:-".main"}

if ! [ -e ${LOCALIZATION_PATH} ]; then
	echo "${LOCALIZATION_PATH} path does not exist. Add these folders and try again."
	exit ${EXIT_FAILURE}
fi

if ! [ -e "${STRINGS_FOLDER}" ]; then
	echo "${STRINGS_FOLDER} path does not exist. Submodule with strings should be named common and contain strings folder."
	exit ${EXIT_FAILURE}
fi

if which php >/dev/null; then
	php ${SCRIPT_DIR}/../aux_scripts/import_strings.php ${LOCALIZATION_PATH} ${STRINGS_FOLDER} ${BUNDLE}
else
	echo "warning: php not installed, install using 'brew install php'"

	exit ${EXIT_FAILURE}
fi