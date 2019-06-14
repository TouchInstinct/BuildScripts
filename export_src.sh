#!/bin/sh

PROJECT_NAME=$1
SRC_FOLDER_NAME=${PROJECT_NAME}-src-$(date +%F)
SRC_DIR=/tmp/${SRC_FOLDER_NAME}

clone_platform() {
    PROJECT_DIR=$1
    PLATFORM=$2

    git clone --recurse-submodules -j8 git@github.com:TouchInstinct/${PROJECT_DIR}-${PLATFORM}.git --branch master
}

mkdir -p ${SRC_DIR}
cd ${SRC_DIR}

clone_platform ${PROJECT_NAME} ios
clone_platform ${PROJECT_NAME} android

find . -name ".git*" -print0 | xargs -0 rm -rf
zip -r ${SRC_FOLDER_NAME}.zip .

open .