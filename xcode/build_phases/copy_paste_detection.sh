# running CPD
echo ${EXECUTABLE_NAME}
pmd cpd --files ${EXECUTABLE_NAME} --exclude ${EXECUTABLE_NAME}/Generated --minimum-tokens 50 --language swift --encoding UTF-8 --format net.sourceforge.pmd.cpd.XMLRenderer > cpd-output.xml --failOnViolation true

# running script
php ./build-scripts/xcode/aux_scripts/cpd_script.php -cpd-xml cpd-output.xml
