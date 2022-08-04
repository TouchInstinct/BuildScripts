require 'json'
require 'mustache'
require 'yaml'

require_relative '../fastlane/touchlane/lib/touchlane/configuration_type'

class String
  def in_current_dir
    "#{__dir__}/#{self}"
  end
end

class ConfigRenderer
    class XCConfigKeys
        DEVELOPMENT_TEAM = "DEVELOPMENT_TEAM"
        PRODUCT_BUNDLE_IDENTIFIER = "PRODUCT_BUNDLE_IDENTIFIER"
        CODE_SIGN_STYLE = "CODE_SIGN_STYLE"
    end

    INHERITED_PREFIX = "$(inherited)"

    private_constant :INHERITED_PREFIX

    def initialize(configurations_file_path, build_parameters_path, configs_folder_name)
      @configurations_file_path = configurations_file_path
      @build_parameters_path = build_parameters_path
      @configs_folder_name = configs_folder_name
    end

    def render_xconfigs
        temp_configs_data_file_path = "configs_data.json".in_current_dir
        generator_path = "build_options_helper/helper.py".in_current_dir
        template_path = "target_xcconfig.mustache".in_current_dir

        # Create config directory if needed
        Dir.mkdir(@configs_folder_name) unless Dir.exist?(@configs_folder_name)

        # Call python script and generate configs to config file
        system("python #{generator_path} -bp #{@build_parameters_path} -o #{__dir__} -r ios_build_settings -p ios")

        # Open settings, configurations and template files
        target_xcconfig_tempate = File.read(template_path)
        $configurations = YAML.load(File.open(@configurations_file_path))
        $config_types = $configurations["types"]

        targets = $configurations["targets"]

        # Run through all target in project
        targets.each do |target_name, target|

            # Need open everytime, because script make some changes only for this target
            configs = JSON.load(File.open(temp_configs_data_file_path))

            # Run through all configs
            configs.each do |config|

                # Take default values
                distribution_type = Touchlane::ConfigurationType.from_account_type(config["account_type"]).type
                properties = target[distribution_type]

                # Add properties from settings file
                properties.each do |key, value|
                    if config["xcconfig_options"].any? { |option| key == option["key"] }
                        config["xcconfig_options"].map! { |option| key == option["key"] ? merge_config_data(key, option["value"], value) : option }
                    else
                        config["xcconfig_options"].append(config_option(key, value))
                    end
                end

                # Add missing properties if needed
                config["xcconfig_options"].concat(generate_missing_properties(target_name, properties, distribution_type))

                # Create settings pack
                config_data = {
                    "target_name": target_name,
                    "abstract_targets_prefix": target["abstract_targets_prefix"],
                    "configuration": config
                }

                # Create file for every setting in loop
                File.open(@configs_folder_name + "/" + target_name + config["name"] + ".xcconfig", 'w') { |file|
                    file.puts(Mustache.render(target_xcconfig_tempate, config_data))
                }
            end

        end

        # Remove config file, it's trash
        File.delete(temp_configs_data_file_path) if File.exist?(temp_configs_data_file_path)
    end

    # Make tuple of key and value become mustache template element
    def config_option(key, value)
        return { "key" => key, "value" => value }
    end

    def merge_config_data(key, config_value, settings_value)
        if settings_value.start_with?(INHERITED_PREFIX)
            new_value = settings_value.split(INHERITED_PREFIX).last
            return config_option(key, config_value + new_value)
        else
            return config_option(key, settings_value)
        end
    end

    # Fetch development team from build configuration
    def fetch_development_team(development_team_key, distribution_type)
        current_config = $config_types[distribution_type]
        team_value = current_config["team_id"]
        return config_option(development_team_key, team_value)
    end

    # Generate missing properties if needed
    def generate_missing_properties(target_name, properties, distribution_type)
        result = []

        # Bundle_id_key should be among the properties (required by fastlane)
        unless properties.key?(XCConfigKeys::PRODUCT_BUNDLE_IDENTIFIER)
            raise "#{target_name}: Could not find #{XCConfigKeys::PRODUCT_BUNDLE_IDENTIFIER} for #{distribution_type}"
        end

        unless properties.key?(XCConfigKeys::DEVELOPMENT_TEAM)
            result.append(fetch_development_team(XCConfigKeys::DEVELOPMENT_TEAM, distribution_type))
        end

        unless properties.key?(XCConfigKeys::CODE_SIGN_STYLE)
            result.append(config_option(XCConfigKeys::CODE_SIGN_STYLE, "Manual"))
        end

        return result
    end
end