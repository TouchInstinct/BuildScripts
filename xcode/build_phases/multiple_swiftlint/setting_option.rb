require 'optparse'
require 'ostruct'

require_relative 'array_extension.rb'

class SettingOption
    def initialize
        @options = OpenStruct.new
        OptionParser.new do |opt|
            opt.on('-p',
                   '--project_root_path STRING',
                   'The path of project directory and contains *.xcodeproj file always. ' +
                   'Example: project_root_path=~/Projects/MyProject/Source/..') { |option|
                @options.project_root_path = option
            }
            opt.on('-r',
                   '--source_root_path STRING',
                   'The path of source directory and may not contains *.xcodeproj file in some cases. ' +
                   'Example: source_root_path=~/Projects/MyProject/') { |option|
                @options.source_root_path = option
            }
            opt.on('-s',
                   '--swiftlint_executable_path STRING',
                   'The executable path of swiftlint') { |option|
                @options.swiftlint_executable_path = option
            }
            opt.on('-c',
                   '--check_mode MODE',
                   'The mode of check is "fully" or "simplified"') { |option|
                @options.check_mode = option
            }
            opt.on('-u',
                   '--use_multiple BOOL',
                   'The flag indicates the use of multiple yaml swiftlint configurations') { |option|
                @options.use_multiple = option
            }
            opt.on('-d',
                   '--source_date DATE',
                   'The date of grouping files according touchin and old swiftlint rules') { |option|
                @options.source_date = option
            }
            opt.on('-tc',
                   '--touchin_swiftlint_yaml_path STRING',
                   'The path to the touchin swiftlint yaml relative to the source directory') { |option|
                @options.touchin_swiftlint_yaml_path = option
            }
            opt.on('-oc',
                   '--old_swiftlint_yaml_path STRING',
                   'The path to the old swiftlint yaml relative to the source directory') { |option|
                @options.old_swiftlint_yaml_path = option
            }
        end.parse!

        if @options.check_mode.to_s.nilOrEmpty?
            @options.check_mode = 'fully'
        end

        if @options.use_multiple.to_s.nilOrEmpty?
            @options.use_multiple = 'false'
        end

        if @options.source_root_path.to_s.nilOrEmpty?
            @options.source_root_path = @options.project_root_path
        end

        if @options.touchin_swiftlint_yaml_path.to_s.nilOrEmpty?
            @options.touchin_swiftlint_yaml_path = File.join(project_root_path, 'build-scripts/xcode/.swiftlint.yml')
        end

        if @options.old_swiftlint_yaml_path.to_s.nilOrEmpty?
            @options.old_swiftlint_yaml_path = File.join(project_root_path, '.swiftlint.yml')
        end
    end

    def method_missing(method, *args, &block)
        @options.send(method, *args, &block)
    end
end
