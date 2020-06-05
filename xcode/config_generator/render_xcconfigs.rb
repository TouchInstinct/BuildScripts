require 'json'
require 'mustache'

# Constants
$configs_folder_name = "TargetConfigurations"
$standard_dev_team = "D4HA43V467"
$enterprise_dev_team = "228J5MMU7S"
$standard_bundle_prefix = "ru.touchin."
$enterprise_bundle_prefix = "com.touchin."
$bundle_id_key = "PRODUCT_BUNDLE_IDENTIFIER"

# create config directory if needed
Dir.mkdir($configs_folder_name) unless Dir.exist?($configs_folder_name)

# call python script and generate configs to config file
system("python gen_configurations.py > configs_data.json")


# open settings + template file
settings = JSON.load(File.open("custom_settings.json"))
target_xcconfig_tempate = File.read("target_xcconfig.mustache")


# set global property
targets = settings["targets"]

# make tuple of key and value become mustache template element
def config_option(key, value)
    return { "key" => key, "value" => value }
end

# return empty array or generated dev team hash
def generate_development_team(development_team_key, account_type)
    team_value = account_type == "Standard" ? $standard_dev_team : $enterprise_dev_team
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
    configs = JSON.load(File.open("configs_data.json"))["configurations"]

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
File.delete("configs_data.json") if File.exist?("configs_data.json")
