GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

RUBY_VERSION="2.7.6"

open_project=(open *.xcworkspace)
install_dev_certs=(bundle exec fastlane SyncCodeSigning type:development readonly:true)
install_pods=(bundle exec pod install || bundle exec pod install --repo-update)

TARGET_MAX_CHAR_NUM=20
## Show help
help:
    @echo ''
    @echo 'Использование:'
    @echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
    @echo ''
    @echo 'Команды:'
    @awk '/^[a-zA-Z\-\_0-9]+:/ { \
        helpMessage = match(lastLine, /^## (.*)/); \
        if (helpMessage) { \
            helpCommand = substr($$1, 0, index($$1, ":")-1); \
            helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
            printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
        } \
    } \
    { lastLine = $$0 }' $(MAKEFILE_LIST)

## Инициализирует проект и устанавливает системные утилиты
init:
    brew bundle

    eval "$(rbenv init -)"

    rbenv install -s ${RUBY_VERSION}
    rbenv global ${RUBY_VERSION}

    if ! gem spec bundler > /dev/null 2>&1; then\
        echo "bundler gem is not installed!";\
        -sudo gem install bundler;\
    fi

    bundle install

    xcodegen

    $(call install_pods)

    bundle exec fastlane install_plugins

    $(call install_dev_certs)

    $(call open_project)

    git config --local core.hooksPath .githooks
    
## Устанавливает поды
pod:
    $(call install_pods)

## Устанавливает сертификат и профили для запуска на девайсе
dev_certs:
    $(call install_dev_certs)

## Открывает папку для ручного редактирования сертификатов и профайлов
update_certs:
    bundle exec fastlane ManuallyUpdateCodeSigning

## Поднимает версию приложения (параметр "X.Y.Z")
bumpAppVersion:
    ifeq ($(version),undefined)
        @echo "Version parameter is missing (ex: x.y.z)" $(target)
    else
        bundle exec fastlane run increment_version_number version_number:$(version)
    endif

## Позволяет быстро открыть workspace проекта
start:
    $(call open_project)

## Очищает содержимое папки DerivedData
clean:
    rm -rf ~/Library/Developer/Xcode/DerivedData/*


