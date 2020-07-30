#https://github.com/TouchInstinct/Styleguide/blob/multiple_swiftlint/IOS/Guides/BuildScripts/Multiple_Swiftlint_Guide.md
require_relative 'setting_option.rb'
require_relative 'strategy_maker.rb'

setting = SettingOption.new
strategy_maker = StrategyMaker.new(setting.project_root_path, setting.swiftlint_executable_path, setting.touchin_swiftlint_yaml_path)

if setting.check_mode.eql? 'fully' and setting.use_multiple.true?
    strategy_maker.run_fully_multiple_strategy(setting.source_date)
elsif setting.check_mode.eql? 'fully' and not setting.use_multiple.true?
    strategy_maker.run_fully_single_strategy
elsif setting.check_mode.eql? 'simplified' and setting.use_multiple.true?
    strategy_maker.run_simplified_multiple_strategy(setting.source_date, setting.source_root_path)
elsif setting.check_mode.eql? 'simplified' and not setting.use_multiple.true?
    strategy_maker.run_simplified_single_strategy(setting.source_root_path)
end
