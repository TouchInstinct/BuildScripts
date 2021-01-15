#!/bin/sh

# Description:
#   This is a wrapper that defines common variables and passes all parameters to sh.
#
# Example of usage:
#   runner.sh copy_paste_detection.sh Generated Localization Pods
#

readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1

readonly TRUE=0
readonly FALSE=1

. $@