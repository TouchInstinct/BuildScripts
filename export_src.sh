#!/bin/sh

PROJECT_NAME=$1
SRC_FOLDER_NAME=${PROJECT_NAME}-src-$(date +%F)
SRC_DIR=./${SRC_FOLDER_NAME}

COMMAND_LINE_ARGUMENTS=$@

clone_platform() {
    PROJECT_DIR=$1
    PLATFORM=$2

    git clone --recurse-submodules -j8 git@github.com:TouchInstinct/${PROJECT_DIR}-${PLATFORM}.git --branch master
}

mkdir -p ${SRC_DIR}
cd ${SRC_DIR}

for argument in ${COMMAND_LINE_ARGUMENTS}
do
  if [ $argument != $PROJECT_NAME ]
  then
    platform=${argument} # all arguments after project name treated as platforms
    clone_platform ${PROJECT_NAME} ${platform}
  fi
done

find . -name ".git*" -print0 | xargs -0 rm -rf
zip -r ${SRC_FOLDER_NAME}.zip .

open .
