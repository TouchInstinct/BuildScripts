#https://github.com/TouchInstinct/Styleguide/blob/multiple_swiftlint/IOS/Guides/BuildScripts/Multiple_Swiftlint_Guide.md
require_relative 'setting_option.rb'
require_relative 'strategy_maker.rb'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

setting = SettingOption.new
maker = StrategyMaker.new(setting.source_directory, setting.pods_directory, setting.touchin_swiftlint_yaml_path)

if setting.check_mode.eql? 'fully' and setting.use_multiple.true?
    maker.make_fully_multiple_strategy(setting.source_date)
elsif setting.check_mode.eql? 'fully' and not setting.use_multiple.true?
    maker.make_fully_single_strategy
elsif setting.check_mode.eql? 'simplified' and setting.use_multiple.true?
    maker.make_simplified_multiple_strategy(setting.source_date, setting.depth_git_count)
elsif setting.check_mode.eql? 'simplified' and not setting.use_multiple.true?
    maker.make_simplified_single_strategy(setting.depth_git_count)
end
