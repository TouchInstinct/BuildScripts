#!/bin/bash

sourceDirectiry=${1:-${TARGET_NAME}}/.. # first argument or TARGET_NAME
sourceTimestamp=$(date -j -f "%Y:%m:%d %H:%M:%S" '2020:05:20 00:00:00' +%s)
touchInstinctYml="$sourceDirectiry/build-scripts/xcode/.swiftlint.yml"
swiftlint=${PODS_ROOT}/SwiftLint/swiftlint
oldYml="$sourceDirectiry/.swiftlint.yml"
excludeDirectories=("vendor" "Tests" "Mock" "Pods" "build-scripts" "nmir-loyaltyTests" "common" ".gem" "node_modules" "Framework" "fastlane")
availableExtensions=(".swift")

function runSwiftlint() {
    config=""
    if [[ $2 = "true" ]]; then
        config=$touchInstinctYml
    else
        config=$oldYml
    fi

    $swiftlint autocorrect --path $1 --config $config && $swiftlint --path $1 --config $config
}

function compareTimestamp() {
    currentFileTimestamp=$(stat -f%B "$1")
    diff=$(($sourceTimestamp - $currentFileTimestamp))
    if [[ $diff -lt 0 ]]; then
        runSwiftlint "$filePath" true
    else
        runSwiftlint "$filePath" false
    fi
}

function isExcludedDirectory() {
    for excludeFile in ${excludeDirectories[*]} ; do
        if [[ $1 == *$excludeFile* ]]; then
            return 1
        fi
    done

    return 0
}

function isValidExtensions() {
    for extension in ${availableExtensions[*]} ; do
        if [[ $1 == *$extension* ]]; then
            return 1
        fi
    done

    return 0
}

function findFiles() {
    for filePath in "$1"/* ; do
        if [[ -d "$filePath"  ]]; then
            isExcludedDirectory "$filePath"
            isExcludedDirectory=$?
            if [[ ($isExcludedDirectory == 0) ]]; then
                findFiles "$filePath"
            fi
        else
            isValidExtensions "$filePath"
            isValidExtensions=$?
            if [[ $isValidExtensions == 1 ]]; then
                compareTimestamp "$filePath"
            fi
        fi
    done
}

findFiles "$sourceDirectiry"
