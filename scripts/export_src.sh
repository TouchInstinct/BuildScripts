#!/bin/sh

# Description:
#   Creates archive with source code of multiple repositories.
#
# Parameters:
#   $1 - github repository name without suffix (project name).
#   $2, $3, ..., $n - repository suffixes (platforms).
#
# Optional environment variables:
#   GIT_BRANCH - branch to use. Default - master.
#
# Example of usage:
#   export_src.sh TestProject ios android backend
#   GIT_BRANCH="develop" ./export_src.sh TestProject ios web
#

if [ -z "${GIT_BRANCH}" ]; then
    GIT_BRANCH="master"
fi

PROJECT_NAME=$1
SRC_FOLDER_NAME="${PROJECT_NAME}-src-$(date +%F)"
SRC_DIR="./${SRC_FOLDER_NAME}"

COMMAND_LINE_ARGUMENTS=$@

clone_platform() {
    PROJECT_NAME=$1
    PLATFORM=$2

    git clone --recurse-submodules -j8 "git@github.com:TouchInstinct/${PROJECT_NAME}-${PLATFORM}.git" --branch "${GIT_BRANCH}"
}

mkdir -p "${SRC_DIR}"
cd "${SRC_DIR}"

for argument in ${COMMAND_LINE_ARGUMENTS}
do
  if [ $argument != $PROJECT_NAME ]; then
    platform=${argument} # all arguments after project name treated as platforms
    clone_platform ${PROJECT_NAME} ${platform}
  fi
done

find . -name ".git*" -print0 | xargs -0 rm -rf
zip -r -q ${SRC_FOLDER_NAME}.zip .

ERR_PATHS=$(find . -name "*[<>:\\|?*]*" | xargs -I %s echo "- %s")
if [ "$ERR_PATHS" ]; then
    echo "Export aborted! Invalid characters found in file or directories name(s):\n$ERR_PATHS"
    exit 1
fi

open .
