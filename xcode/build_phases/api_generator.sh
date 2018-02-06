VERSION=$1
FILE_NAME="api-generator-${VERSION}.jar"

# download api generator
link="https://dl.bintray.com/touchin/touchin-tools/ru/touchin/api-generator/${VERSION}/${FILE_NAME}"
. build-scripts/xcode/aux_scripts/download_file.sh ${FILE_NAME} ${link}

# execute api generator
java -jar "Downloads/${FILE_NAME}" generate-client-code --output-language SWIFT --specification-path common/api --output-path ${PROJECT_NAME}/Generated --single-file true
