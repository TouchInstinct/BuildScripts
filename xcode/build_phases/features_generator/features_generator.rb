require 'yaml'

require_relative '../../managers/managers'
require_relative '../../templates/templates'

# Input files paths
build_settings_file_path = ARGV[0]
generated_features_enum_file_path = ARGV[1]

build_settings_features_list = Managers::FileManager.load_from_file_YAML(build_settings_file_path)["features"]

if build_settings_features_list.nil? or build_settings_features_list.empty?
	raise "There are no features in " + build_settings_file_path
end

# Generate enum Feature Toggles
features_enum_template = Templates::FeatureTemplates.features_enum
utils = Managers::TemplateManager.new(build_settings_features_list)

rendered_enum = utils.render(features_enum_template).strip

Managers::FileManager.save_data_to_file(generated_features_enum_file_path, rendered_enum)
