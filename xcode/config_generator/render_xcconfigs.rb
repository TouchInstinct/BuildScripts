require 'json'
require 'mustache'

# Constants
configs_folder_name = "TargetConfigurations"
standard_dev_team = "D4HA43V467"
enterprise_dev_team = "228J5MMU7S"

# create config files if needed
File.new("configs_data.json", 'a')
Dir.mkdir(configs_folder_name) unless Dir.exist?(configs_folder_name)

# call python script and generate configs to config file
system("python gen_configurations.py > configs_data.json")


# open settings + template file
settings = JSON.load(File.open("settings.json"))
target_xcconfig_tempate = File.read("target_xcconfig.mustache")


# set global property
targets = settings["targets"]

# make tuple of key and value become mustache template element
def config_option(key, value)
    return { "key" => key, "value" => value }
end

# return empty array or generated dev team hash
def development_team_if_needed(properties, account_type)
    development_team_key = "DEVELOPMENT_TEAM"
    if properties.key?(development_team_key)
        return []
    end

    team_value = account_type == "Standard" ? standard_dev_team : enterprise_dev_team
    return [config_option(development_team_key, team_value)]
end

# return empty array or generated provisioning profile hash
def provisioning_profile_if_needed(properties, account_type)
    provisioning_key = "PROVISIONING_PROFILE_SPECIFIER"
    if properties.key?(provisioning_key)
        return []
    end

    bundle_id = properties["PRODUCT_BUNDLE_IDENTIFIER"]
    if account_type == "AppStore"
        app_store_profiile = "match AppStore " + bundle_id
        return [config_option(provisioning_key, app_store_profiile)]
    else
        return [config_option(provisioning_key, bundle_id)]
    end
end

# generate missing properties if needed
def generate_missing_properties(properties, account_type)
    result = []
    result.concat(development_team_if_needed(properties, account_type))
    result.concat(provisioning_profile_if_needed(properties, account_type))
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
        config["xcconfig_options"].concat(generate_missing_properties(properties, account_type))

        # create settings pack
        config_data = {
            "target_name": target_name,
            "configuration": config
        }

        # create file for every setting in loop
        File.open(configs_folder_name + "/" + target_name + config["name"] + ".xcconfig", 'w') { |file|
            file.puts(Mustache.render(target_xcconfig_tempate, config_data))
        }
    end

end

# remove config file, it's trash
File.delete("configs_data.json") if File.exist?("configs_data.json")
