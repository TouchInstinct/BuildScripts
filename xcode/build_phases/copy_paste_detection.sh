if which pmd >/dev/null; then
    # running CPD
    readonly SOURCES_DIR=${1:-${PROJECT_DIR}} # first argument or PROJECT_DIR
    readonly REPORTS_DIR=${PROJECT_DIR}/code-quality-reports
    readonly FILES_TO_EXCLUDE=`find ${SOURCES_DIR} -type d -name Localization -or -name Generated -or -name Carthage -or -name Pods | paste -sd " " -`

    mkdir ${REPORTS_DIR}

    pmd cpd --files ${SOURCES_DIR} --exclude ${FILES_TO_EXCLUDE} --minimum-tokens 50 --language swift --encoding UTF-8 --format net.sourceforge.pmd.cpd.XMLRenderer > ${REPORTS_DIR}/cpd-output.xml --failOnViolation true

    php ./build-scripts/xcode/aux_scripts/cpd_script.php ${REPORTS_DIR}/cpd-output.xml | tee ${REPORTS_DIR}/CPDLog.txt

    # Make paths relative to SOURCES_DIR, so different developers won't rewrite entire file
    readonly SED_REPLACEMENT_STRING=$(echo ${SOURCES_DIR} | sed "s/\//\\\\\//g")

    sed -i '' "s/${SED_REPLACEMENT_STRING}//g" "${REPORTS_DIR}/CPDLog.txt"
else
    echo "warning: pmd not installed, install using 'brew install pmd'"
    exit 1
fi
