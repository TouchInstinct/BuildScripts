#!/bin/sh

PROJECT_PATH=$1

cd ${PROJECT_PATH}

# Install ruby dependencies (cocoapods, fastlane, etc.)

bundle install

# Install Homebrew

if [[ $(command -v brew) == "" ]]; then

    # Prevent "Press RETURN to continue or any other key to abort" message when installing Homebrew

    export CI=true

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Install brew dependencies (carthage, etc.)

brew bundle

# Install pods dependencies

bundle exec pod repo update
bundle exec pod install

# Install carthage dependencies

carthage bootstrap --platform iOS

case $2 in
    --InstallDevelopmentCodeSigning)
        # Install certificates & provision profiles for development

        cd ${PROJECT_PATH}/fastlane

        bundle exec fastlane SyncCodeSigning
    ;;
esac

