#!/bin/sh

# Description:
#   Generates API models & methods.
#
# Parameters:
#   $1 - api generator version.
#   $2 - path to generated code directory
#
# Required environment variables:
#   SRCROOT - path to project folder.
#
# Optional environment variables:
#   OUTPUT_PATH - path to Generated folder.
#   API_SPEC_DIR - path to api specification folder
#   VERBOSE - print debug messages
#   API_NAME - project name that will be used by generator (example: OUTPUT_PATH/API_NAME/Classes )
#
# Examples of usage:
#   . api_generator.sh 1.4.0-beta1
#   . api_generator.sh 1.4.0-beta1 ${TARGET_NAME}/Generated
#

readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1

readonly TRUE=0
readonly FALSE=1

readonly LOG_TAG="API-GENERATOR"

notice()
{
    echo "${LOG_TAG}:NOTICE: ${1}"
}

debug()
{
    if [ ! -z "${VERBOSE}" ]; then
        echo "${LOG_TAG}:DEBUG: ${1}"
    fi
}

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

is_single_file()
{
    if [ -z "${SINGLE_FILE}" ]; then
        echo "true"
        return
    fi

    local -r STR_MODE=`tr "[:upper:]" "[:lower:]" <<< ${SINGLE_FILE}`

    if [ ${STR_MODE} == "no" ] || [ ${STR_MODE} == "false" ] || [ ${STR_MODE} == "0" ]; then
        echo "false"
    else 
        echo "true"
    fi
}

get_current_commit()
{
    if [ -z "${API_SPEC_DIR}" ]; then
        if [ ! -z "${1}" ]; then
            echo `git -C ${1} rev-parse --verify HEAD`
        else
            echo `git rev-parse --verify HEAD`
        fi
    else
        echo `git -C ${API_SPEC_DIR} rev-parse --verify HEAD`
    fi
}

is_nothing_changed_since_last_check()
{
    if is_force_run; then
        notice "Force run detected. Skipping commits comparison."
        return ${EXIT_FAILURE}
    fi

    if [ -z "${COMMIT_FILE_PATH}" ]; then
        if [ ! -z "${1}" ]; then
            local -r COMMIT_FILE_PATH=${1}
        else
            debug "COMMIT_FILE_PATH should be defined or passed as first argument!"
            return ${EXIT_FAILURE}
        fi
    fi

    local -r CURRENT_COMMIT=`get_current_commit`

    local -r LAST_CHECKED_COMMIT=`cat ${COMMIT_FILE_PATH} 2> /dev/null || echo ""`

    if [ ${CURRENT_COMMIT} = "${LAST_CHECKED_COMMIT}" ]; then
        return ${EXIT_SUCCESS}
    else
        return ${EXIT_FAILURE}
    fi
}

record_current_commit()
{
    if is_force_run; then
        notice "Force run detected. Commit won't be recorder."
        exit ${EXIT_SUCCESS}
    fi

    if [ -z "${COMMIT_FILE_PATH}" ]; then
        if [ ! -v "${1}" ]; then
            local -r COMMIT_FILE_PATH=${1}
        else
            debug "COMMIT_FILE_PATH should be defined or passed as second argument!"
            return ${EXIT_FAILURE}
        fi
    fi

    local -r CURRENT_COMMIT=`get_current_commit`

    echo ${CURRENT_COMMIT} > ${COMMIT_FILE_PATH}
}

openapi_codegen()
{
    if [ -z "${OPEN_API_SPEC_PATH}" ]; then
        if [ ! -v "${1}" ]; then
            local -r OPEN_API_SPEC_PATH=${1}
        else
            debug "OPEN_API_SPEC_PATH should be defined or passed as first argument!"
            return ${EXIT_FAILURE}
        fi
    fi

    if [ -z "${OUTPUT_PATH}" ]; then
        if [ ! -v "${2}" ]; then
            local -r OUTPUT_PATH=${2}
        else
            debug "OUTPUT_PATH should be defined or passed as second argument!"
            return ${EXIT_FAILURE}
        fi
    fi

    if [ -z "${VERSION}" ]; then
        if [ ! -v "${3}" ]; then
            local -r VERSION=${3}
        else
            debug "VERSION should be defined or passed as third argument!"
            return ${EXIT_FAILURE}
        fi
    fi

    if [ -z "${API_NAME}" ]; then
        local -r API_NAME="${PROJECT_NAME}API"
    fi

    notice "OpenAPI spec generation for ${OPEN_API_SPEC_PATH}"

    local -r CODEGEN_VERSION="3.0.33"

    local -r CODEGEN_FILE_NAME="swagger-codegen-cli-${CODEGEN_VERSION}.jar"
    local -r CODEGEN_DOWNLOAD_URL="https://repo1.maven.org/maven2/io/swagger/codegen/v3/swagger-codegen-cli/${CODEGEN_VERSION}/${CODEGEN_FILE_NAME}"

    . build-scripts/xcode/aux_scripts/download_file.sh ${CODEGEN_FILE_NAME} ${CODEGEN_DOWNLOAD_URL}

    local -r TINETWORKING_CODEGEN_FILE_NAME="codegen-${VERSION}.jar"

    local -r DOWNLOAD_URL="https://maven.dev.touchin.ru/ru/touchin/codegen/${VERSION}/${TINETWORKING_CODEGEN_FILE_NAME}"

    . build-scripts/xcode/aux_scripts/download_file.sh ${TINETWORKING_CODEGEN_FILE_NAME} ${DOWNLOAD_URL}

    rm -rf ${OUTPUT_PATH}/${API_NAME} # remove previously generated API (if exists)

    java -cp "Downloads/${CODEGEN_FILE_NAME}:Downloads/${TINETWORKING_CODEGEN_FILE_NAME}" io.swagger.codegen.v3.cli.SwaggerCodegen generate -l TINetworking -i ${OPEN_API_SPEC_PATH} -o ${OUTPUT_PATH} --additional-properties projectName=${API_NAME}

    # flatten folders hierarchy

    mv ${OUTPUT_PATH}/${API_NAME}/Classes/Swaggers/* ${OUTPUT_PATH}/${API_NAME}/

    rm -rf ${OUTPUT_PATH}/${API_NAME}/Classes
}

api_generator_codegen()
{
    if [ -z "${API_SPEC_DIR}" ]; then
        if [ ! -v "${1}" ]; then
            local -r API_SPEC_DIR=${1}
        else
            debug "API_SPEC_DIR should be defined or passed as first argument!"
            return ${EXIT_FAILURE}
        fi
    fi

    if [ -z "${OUTPUT_PATH}" ]; then
        if [ ! -v "${2}" ]; then
            local -r OUTPUT_PATH=${2}
        else
            debug "OUTPUT_PATH should be defined or passed as second argument!"
            return ${EXIT_FAILURE}
        fi
    fi

    if [ -z "${VERSION}" ]; then
        if [ ! -v "${3}" ]; then
            local -r VERSION=${3}
        else
            debug "VERSION should be defined or passed as third argument!"
            return ${EXIT_FAILURE}
        fi
    fi

    notice "api-generator spec generation for ${API_SPEC_DIR}/main.json"

    local -r FILE_NAME="api-generator-${VERSION}.jar"
    local -r DOWNLOAD_URL="https://maven.dev.touchin.ru/ru/touchin/api-generator/${VERSION}/${FILE_NAME}"

    . build-scripts/xcode/aux_scripts/download_file.sh ${FILE_NAME} ${DOWNLOAD_URL}
    java -Xmx6g -jar "Downloads/${FILE_NAME}" generate-client-code --output-language SWIFT --specification-path ${API_SPEC_DIR} --output-path ${OUTPUT_PATH} --single-file $(is_single_file)
}

readonly BUILD_PHASES_DIR=${SRCROOT}/build_phases

mkdir -p ${BUILD_PHASES_DIR}

readonly COMMIT_FILE_PATH=${BUILD_PHASES_DIR}/api-generator-commit

if is_nothing_changed_since_last_check; then
    notice "Nothing was changed api generation skipped."
    exit ${EXIT_SUCCESS}
fi

readonly VERSION=$1

if [ -z "${OUTPUT_PATH}" ]; then
    if [ ! -z "${2}" ]; then
        readonly OUTPUT_PATH=${2}
    else
        readonly OUTPUT_PATH="Generated"
    fi
fi

if [ -z "${API_SPEC_DIR}" ]; then
    readonly API_SPEC_DIR="common/api"
fi

mkdir -p ${OUTPUT_PATH}

readonly OPEN_API_SPEC_PATH=`find ${API_SPEC_DIR} -maxdepth 1 -name '*.yaml' -o -name '*.yml' | head -n 1`

if [ -f "${OPEN_API_SPEC_PATH}" ]; then
    openapi_codegen
elif [ -f "${API_SPEC_DIR}/main.json" ]; then
    api_generator_codegen
else
    notice "No api spec found!"
    exit ${EXIT_FAILURE}
fi

if [ $? -ne ${EXIT_FAILURE} ]; then
    record_current_commit 
fi
