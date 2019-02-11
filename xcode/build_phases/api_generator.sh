VERSION=$1
SHOULD_GENERATE=$2

echo "Optional Api Generator Build Phase"

if [ "${SHOULD_GENERATE}" == "false" ]; then
    echo "SHOULD_GENERATE == false"
    exit 0
fi

echo "SHOULD_GENERATE == true"

FILE_NAME="api-generator-${VERSION}.jar"

# download api generator
link="https://dl.bintray.com/touchin/touchin-tools/ru/touchin/api-generator/${VERSION}/${FILE_NAME}"
. build-scripts/xcode/aux_scripts/download_file.sh ${FILE_NAME} ${link}

# execute api generator
java -jar "Downloads/${FILE_NAME}" generate-client-code --output-language SWIFT --specification-path common/api --output-path ${PROJECT_NAME}/Generated --single-file true
