readonly BUILD_SCRIPTS_DIR=${1:-${PROJECT_DIR}} # first argument or PROJECT_DIR
. $BUILD_SCRIPTS_DIR/build-scripts/xcode/aux_scripts/certificates_readme_generator.sh > $PROJECT_DIR/Certificates/README.md
