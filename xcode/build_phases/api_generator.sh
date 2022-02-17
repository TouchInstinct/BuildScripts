#!/bin/sh

# Description:
#   Generates API models & methods.
#
# Parameters:
#   $1 - api generator version.
#
# Optional environment variables:
#   OUTPUT_PATH - path to Generated folder.
#
# Examples of usage:
#   . api_generator.sh 1.4.0-beta1
#   . api_generator.sh 1.4.0-beta1 ${TARGET_NAME}/Generated
#

readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1

readonly TRUE=0
readonly FALSE=1

is_force_run()
{
    if [ -z "${FORCE_RUN}" ]; then
        return ${FALSE}
    fi

    local -r STR_MODE=`tr "[:upper:]" "[:lower:]" <<< ${FORCE_RUN}`

    if [ ${STR_MODE} == "yes" ] || [ ${STR_MODE} == "true" ] || [ ${STR_MODE} == "1" ]; then
        return ${TRUE}
    fi

    return ${FALSE}
}

get_current_commit()
{
    if [ -z "${CURRENT_COMMIT}" ]; then
        if [ -z "${REPO_PATH}" ]; then
            if [ ! -z "${1}" ]; then
                echo `git -C ${1} rev-parse --verify HEAD`
            else
                echo `git rev-parse --verify HEAD`
            fi
        else
            echo `git -C ${REPO_PATH} rev-parse --verify HEAD`
        fi
    else
        echo ${CURRENT_COMMIT}
    fi
}

is_nothing_changed_since_last_check()
{
    if is_force_run; then
        echo "Force run detected. Skipping commits comparison."
        return ${EXIT_FAILURE}
    fi

    if [ -z "${COMMIT_FILE_PATH}" ]; then
        if [ ! -z "${1}" ]; then
            local -r COMMIT_FILE_PATH=${1}
        else
            echo "COMMIT_FILE_PATH should be defined or passed as first argument!"
            return ${EXIT_FAILURE}
        fi
    fi

    if [ -z "${2}" ]; then
        local -r CURRENT_COMMIT=`get_current_commit`
    else
        local -r CURRENT_COMMIT=${2}
    fi

    local -r LAST_CHECKED_COMMIT=`cat ${COMMIT_FILE_PATH}` || ""

    if [ ${CURRENT_COMMIT} = "${LAST_CHECKED_COMMIT}" ]; then
        return ${EXIT_SUCCESS}
    else
        return ${EXIT_FAILURE}
    fi
}

record_current_commit()
{
    if is_force_run; then
        echo "Force run detected. Commit won't be recorder."
        exit ${EXIT_SUCCESS}
    fi

    if [ -z "${1}" ]; then
        local -r CURRENT_COMMIT=`get_current_commit`
    else
        local -r CURRENT_COMMIT=${1}
    fi

    if [ -z "${COMMIT_FILE_PATH}" ]; then
        if [ ! -v "${2}" ]; then
            local -r COMMIT_FILE_PATH=${2}
        else
            echo "COMMIT_FILE_PATH should be defined or passed as second argument!"
            return ${EXIT_FAILURE}
        fi
    fi

    echo ${CURRENT_COMMIT} > ${COMMIT_FILE_PATH}
}

readonly BUILD_PHASES_DIR=${SRCROOT}/build_phases

mkdir -p ${BUILD_PHASES_DIR}

readonly COMMIT_FILE_PATH=${BUILD_PHASES_DIR}/api-generator-commit

readonly REPO_PATH="common"

if is_nothing_changed_since_last_check; then
    echo "Nothing was changed models generation skipped."
    exit ${EXIT_SUCCESS}
fi

VERSION=$1
FILE_NAME="api-generator-${VERSION}.jar"

if [ -z "${OUTPUT_PATH}" ]; then
    if [ ! -z "${2}" ]; then
        readonly OUTPUT_PATH=${2}
    else
        readonly OUTPUT_PATH="Generated"
    fi
fi

mkdir -p ${OUTPUT_PATH}

# download api generator
readonly DOWNLOAD_URL="https://maven.dev.touchin.ru/ru/touchin/api-generator/${VERSION}/${FILE_NAME}"
. build-scripts/xcode/aux_scripts/download_file.sh ${FILE_NAME} ${DOWNLOAD_URL}

# execute api generator
java -Xmx6g -jar "Downloads/${FILE_NAME}" generate-client-code --output-language SWIFT --specification-path common/api --output-path ${OUTPUT_PATH} --single-file true

record_current_commit
