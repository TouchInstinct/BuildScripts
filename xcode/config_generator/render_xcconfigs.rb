require 'json'
require 'mustache'
require 'yaml'

# Usage:  render_xcconfigs.rb <CUSTOM SETTINGS PATH> <CONFIGURATIONS.YAML PATH>
#
# Result: Adds .xcconfig files to $configs_folder_name directory. 
#         Files are only being added and changed, not removed!
#         It is recommended to remove old .xcconfig files before running this script.


# Constants
$configs_folder_name = "TargetConfigurations"
$standard_bundle_prefix = "ru.touchin."
$enterprise_bundle_prefix = "com.touchin."
$bundle_id_key = "PRODUCT_BUNDLE_IDENTIFIER"

class String
  def in_current_dir
    "#{__dir__}/#{self}"
  end
end

custom_settings_path = ARGV[0]
configurations_yaml_file = ARGV[1]
temp_configs_data_file = "configs_data.json".in_current_dir

# create config directory if needed
Dir.mkdir($configs_folder_name) unless Dir.exist?($configs_folder_name)

# call python script and generate configs to config file
system("python #{"gen_configurations.py".in_current_dir} > #{temp_configs_data_file}")


# open settings, configurations and template files
settings = JSON.load(File.open(custom_settings_path))
target_xcconfig_tempate = File.read("target_xcconfig.mustache".in_current_dir)
$configurations = YAML.load(File.open(configurations_yaml_file))

# set global property
targets = settings["targets"]

# make tuple of key and value become mustache template element
def config_option(key, value)
    return { "key" => key, "value" => value }
end

# return empty array or generated dev team hash
def generate_development_team(development_team_key, account_type)
    current_config = case account_type
                     when "Standard"
                         $configurations["development"]
                     when "Enterprise"
                         $configurations["enterprise"]
                     when "AppStore"
                         $configurations["appstore"]
                     else
                         raise "Error: Unsupported distribution type #{account_type}" 
                     end
    team_value = current_config["team_id"]
    return config_option(development_team_key, team_value)
end

# return empty array or generated provisioning profile hash
def generate_provisioning_profile(provisioning_key, bundle_id, account_type)
    if account_type == "AppStore"
        app_store_profiile = "match AppStore " + bundle_id
        return config_option(provisioning_key, app_store_profiile)
    else
        return config_option(provisioning_key, bundle_id)
    end
end

def generate_bundle_id(target_name, account_type)
    bundle_id_prefix = account_type == "Standard" ? $standard_bundle_prefix : $enterprise_bundle_prefix
    bundle_id = bundle_id_prefix + target_name
    return config_option($bundle_id_key, bundle_id)
end

def generate_google_service_info_plist_path(google_service_info_plist_key, target_name, account_type)
    google_service_info_plist_path = target_name + "/Resources/"
    
    if account_type == "AppStore"
        google_service_info_plist_path += "AppStore-GoogleService-Info.plist"
    elsif account_type == "Enterprise"
        google_service_info_plist_path += "Enterprise-GoogleService-Info.plist"
    else
        google_service_info_plist_path += "Standard-GoogleService-Info.plist"
    end
    
    return config_option(google_service_info_plist_key, google_service_info_plist_path)
end

# generate missing properties if needed
def generate_missing_properties(target_name, properties, account_type)
    result = []
    development_team_key = "DEVELOPMENT_TEAM"
    provisioning_key = "PROVISIONING_PROFILE_SPECIFIER"
    google_service_info_plist_key = "GOOGLE_SERVICE_INFO_PLIST_PATH"

    unless properties.key?($bundle_id_key)
        bundle_id_config = generate_bundle_id(target_name, account_type)
        bundle_id = bundle_id_config["value"]
        result.append(bundle_id_config)
    else
        bundle_id = properties[$bundle_id_key]
    end

    unless properties.key?(development_team_key)
        result.append(generate_development_team(development_team_key, account_type))
    end

    unless properties.key?(provisioning_key)
        result.append(generate_provisioning_profile(provisioning_key, bundle_id, account_type))
    end
    
    unless properties.key?(google_service_info_plist_key)
        result.append(generate_google_service_info_plist_path(google_service_info_plist_key, target_name, account_type))
    end

    return result
end

# run through all target in project
targets.each do |target|

    # need open everytime, because script make some changes only for this target
    configs = JSON.load(File.open(temp_configs_data_file))["configurations"]

    # run through all configs
    configs.each do |config|

        # take default values
        account_type = config["account_type"]
        target_name = target.keys.first
        properties = target[target_name][account_type]

        # add properties from settings file
        properties.each do |key, value|
          config["xcconfig_options"].append(config_option(key, value))
        end

        # add missing properties if needed
        config["xcconfig_options"].concat(generate_missing_properties(target_name, properties, account_type))

        # create settings pack
        config_data = {
            "target_name": target_name,
            "configuration": config
        }

        # create file for every setting in loop
        File.open($configs_folder_name + "/" + target_name + config["name"] + ".xcconfig", 'w') { |file|
            file.puts(Mustache.render(target_xcconfig_tempate, config_data))
        }
    end

end

# remove config file, it's trash
File.delete(temp_configs_data_file) if File.exist?(temp_configs_data_file)
