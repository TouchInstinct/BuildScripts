require 'yaml'
require 'fileutils'

class YamlManager
    def initialize(swiftlint_yaml_path)
        @swiftlint_yaml_path = swiftlint_yaml_path
        @configuration ||= YAML.load(File.read(@swiftlint_yaml_path))
    end
    
    def get_configuration(key)
        @configuration[key]
    end

    def update(key, new_configuration_values)
        @configuration[key] = new_configuration_values
        save_settings(@configuration)
    end

    private

    def save_settings(settings)
        File.write(@swiftlint_yaml_path, settings.to_yaml)
    end
end
