#!/bin/bash

export INFO_PATH="$(dirname $PWD)"

while read -r token file; do
do_stuff_with "$token"
do_stuff_with "$file"
done < $INFO_PATH/Figma/test.txt

SCRIPT_PATH=`dirname $0`
ruby $SCRIPT_PATH/screenshots.rb --token="$token" --file="$file" --folder=$INFO_PATH/fastlane/screenshots
