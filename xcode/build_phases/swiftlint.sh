#!/bin/sh

# Description:
#   Runs swiftlint with selected or default config file.
#
# Parameters:
#   $1 - path to swiftlint executable.
#   $2 - path to swiftlint config.
#
# Required environment variables:
#   SCRIPT_DIR - directory of current script.
#   SRCROOT - project directory.
#   PODS_ROOT - cocoapods installation directory (eg. ${SRCROOT}/Pods).
#
# Available environment variables:
#   FORCE_LINT - lint all project.
#
# Optional environment variables:
#   SWIFTLINT_EXECUTABLE - path to swiftlint executable.
#   SWIFTLINT_CONFIG_PATH - path to swiftlint config.
#   SCRIPT_INPUT_FILE_COUNT - number of files listed in "Input files" of build phase.
#   SCRIPT_INPUT_FILE_{N} - file path to directory that should be checked.
#   FORCE_LINT - lint all project.
#
# Example of usage:
#   swiftlint.sh
#   FORCE_LINT=true; swiftlint.sh
#   swiftlint.sh Pods/Swiftlint/swiftlint build-scripts/xcode/.swiftlint.yml
#

readonly SOURCES_DIRS=`. ${SCRIPT_DIR}/common/read_input_file_names.sh "\n" ${SRCROOT}`

if [ -z "${SWIFTLINT_EXECUTABLE}" ]; then
    if [ ! -z "${1}" ]; then
        readonly SWIFTLINT_EXECUTABLE=${1}
    else
        readonly SWIFTLINT_EXECUTABLE=${PODS_ROOT}/SwiftLint/swiftlint
    fi
fi

if [ -z "${SWIFTLINT_CONFIG_PATH}" ]; then
    if [ ! -z "${2}" ]; then
        readonly SWIFTLINT_CONFIG_PATH=${2}
    else
        readonly SWIFTLINT_CONFIG_PATH=${SCRIPT_DIR}/../.swiftlint.yml
    fi
fi

if [ ! -z "${FORCE_LINT}" ]; then
    # Если задана переменная FORCE_LINT, то проверяем все файлы проекта
    for SOURCE_DIR in ${SOURCES_DIRS}; do
        ${SWIFTLINT_EXECUTABLE} autocorrect --path ${SOURCE_DIR} --config ${SWIFTLINT_CONFIG_PATH}
        ${SWIFTLINT_EXECUTABLE} --path ${SOURCE_DIR} --config ${SWIFTLINT_CONFIG_PATH}
    done
else 
    # Xcode упадет, если будем использовать большое количество Script Input Files, 
    # так как просто переполнится стек - https://unix.stackexchange.com/questions/357843/setting-a-long-environment-variable-breaks-a-lot-of-commands
    # Поэтому воспользуемся "скрытым" параметром Swiflint - https://github.com/realm/SwiftLint/pull/3313
    # Создадим временный файл swiftlint_files с префиксом @ и в нем уже определим список файлов
    # необходимых для линтовки :)

    lint_files_path="${SRCROOT}/build_phases/swiftlint_files"

    if [ ! -z "${lint_files_path}" ]; then
        > ${lint_files_path} # Если файл существует, то просто его очистим
    else
        touch ${lint_files_path} # Если файла нет, то создадим его
    fi

    # Проходимся по папкам, которые требуют линтовки
    for SOURCE_DIR in ${SOURCES_DIRS}; do

        # Отбираем файлы, которые были изменены или созданы
        source_unstaged_files=$(git diff --diff-filter=d --name-only ${SOURCE_DIR} | grep "\.swift$")
        source_staged_files=$(git diff --diff-filter=d --name-only --cached ${SOURCE_DIR} | grep "\.swift$")

        if [ ! -z "${source_unstaged_files}" ]; then
            echo "${source_unstaged_files}" >> ${lint_files_path}
        fi

        if [ ! -z "${source_staged_files}" ]; then
            echo "${source_staged_files}" >> ${lint_files_path}
        fi
    done

    swiftlint_files_path="@${lint_files_path}"

    ${SWIFTLINT_EXECUTABLE} autocorrect --path ${swiftlint_files_path} --config ${SWIFTLINT_CONFIG_PATH} --force-exclude --use-alternative-excluding
    ${SWIFTLINT_EXECUTABLE} --path ${swiftlint_files_path} --config ${SWIFTLINT_CONFIG_PATH} --force-exclude --use-alternative-excluding
fi
