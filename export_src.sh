#!/bin/sh

PROJECT_DIR=$1
PLATFORM=$2

cd /tmp/
git clone --recurse-submodules -j8 git@github.com:TouchInstinct/${PROJECT_DIR}-${PLATFORM}.git --branch develop
cd ${PROJECT_DIR}-${PLATFORM}
find . -name ".git*" -print0 | xargs -0 rm -rf
zip -r ${PROJECT_DIR}-${PLATFORM}-src-$(date +%F).zip .

open .