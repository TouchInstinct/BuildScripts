require 'json'
require 'mustache'
require 'yaml'

#
# Usage:  render_xcconfigs.rb <configurations.yaml> <build_parameters.yaml> [<ouptut folder>]
#
# Result: Adds .xcconfig files to ouptut folder.
#         Files are only being added and changed, not removed!
#         It is recommended to remove old .xcconfig files before running this script.
#

class String
  def in_current_dir
    "#{__dir__}/#{self}"
  end
end

# Input files paths
configurations_file_path = ARGV[0]
temp_configs_data_file_path = "configs_data.json".in_current_dir
generator_path = "build_options_helper/helper.py".in_current_dir
template_path = "target_xcconfig.mustache".in_current_dir
build_parameters_path = ARGV[1]
configs_folder_name = ARGV[2] || "TargetConfigurations"

# Create config directory if needed
Dir.mkdir(configs_folder_name) unless Dir.exist?(configs_folder_name)

# Call python script and generate configs to config file
system("python #{generator_path} -bp #{build_parameters_path} -o #{__dir__} -r ios_build_settings -p ios")

# Open settings, configurations and template files
target_xcconfig_tempate = File.read(template_path)
$configurations = YAML.load(File.open(configurations_file_path))
$config_types = $configurations["types"]

# Set global property
targets = $configurations["targets"]

# Make tuple of key and value become mustache template element
def config_option(key, value)
    return { "key" => key, "value" => value }
end

# Maps lane prefix to distribution type
def distribution_type_of(account_type)
  case account_type
  when "Standard"
    "development"
  when "Enterprise"
    "enterprise"
  when "AppStore"
    "appstore"
  else
    raise "Error: Unsupported distribution type #{account_type}"
  end
end

# Fetch development team from build configuration
def fetch_development_team(development_team_key, distribution_type)
    current_config = $config_types[distribution_type]
    team_value = current_config["team_id"]
    return config_option(development_team_key, team_value)
end

# Return empty array or generated provisioning profile hash
def generate_provisioning_profile(provisioning_key, bundle_id, distribution_type)
  case distribution_type
  when "appstore"
    app_store_profile = "match AppStore " + bundle_id
    config_option(provisioning_key, app_store_profile)
  else
    config_option(provisioning_key, bundle_id)
  end
end

def generate_google_service_info_plist_path(google_service_info_plist_key, target_name, distribution_type)
    google_service_info_plist_path = target_name + "/Resources/"

    path_suffix = case distribution_type
                  when "development"
                    "Standard-GoogleService-Info.plist"
                  when "enterprise"
                    "Enterprise-GoogleService-Info.plist"
                  else
                    "AppStore-GoogleService-Info.plist"
                  end

    return config_option(google_service_info_plist_key, google_service_info_plist_path + path_suffix)
end

# Generate missing properties if needed
def generate_missing_properties(target_name, properties, distribution_type)
    result = []
    development_team_key = "DEVELOPMENT_TEAM"
    provisioning_key = "PROVISIONING_PROFILE_SPECIFIER"
    google_service_info_plist_key = "GOOGLE_SERVICE_INFO_PLIST_PATH"
    bundle_id_key = "PRODUCT_BUNDLE_IDENTIFIER"

    # Bundle_id_key should be among the properties (required by fastlane)
    unless properties.key?(bundle_id_key)
        raise "#{target_name}: Could not find #{bundle_id_key} for #{distribution_type}"
    end

    unless properties.key?(development_team_key)
        result.append(fetch_development_team(development_team_key, distribution_type))
    end

    unless properties.key?(provisioning_key)
        result.append(generate_provisioning_profile(provisioning_key, properties[bundle_id_key], distribution_type))
    end

    unless properties.key?(google_service_info_plist_key)
        result.append(generate_google_service_info_plist_path(google_service_info_plist_key, target_name, distribution_type))
    end

    return result
end

# Run through all target in project
targets.each do |target_name, target|

    # Need open everytime, because script make some changes only for this target
    configs = JSON.load(File.open(temp_configs_data_file_path))

    # Run through all configs
    configs.each do |config|

        # Take default values
        distribution_type = distribution_type_of(config["account_type"])
        properties = target[distribution_type]

        # Add properties from settings file
        properties.each do |key, value|
          config["xcconfig_options"].append(config_option(key, value))
        end

        # Add missing properties if needed
        config["xcconfig_options"].concat(generate_missing_properties(target_name, properties, distribution_type))

        # Create settings pack
        config_data = {
            "target_name": target_name,
            "configuration": config
        }

        # Create file for every setting in loop
        File.open(configs_folder_name + "/" + target_name + config["name"] + ".xcconfig", 'w') { |file|
            file.puts(Mustache.render(target_xcconfig_tempate, config_data))
        }
    end

end

# Remove config file, it's trash
File.delete(temp_configs_data_file_path) if File.exist?(temp_configs_data_file_path)
