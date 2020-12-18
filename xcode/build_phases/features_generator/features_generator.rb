require 'yaml'
require 'erb'

require_relative "../../managers/managers"

# Input files paths
build_settings_file_path = ARGV[0]
generated_features_enum_file_path = ARGV[1]

features_enum_template =
"
//MARK: - Feature toggles

public enum FeatureToggle: String, Codable, RawRepresentable, CaseIterable {
    <% for @feature in @features %>
    case <%= @feature %>
    <% end %>
}
"

class FeatureUtils
  include ERB::Util

  attr_accessor :features

  def initialize(features)
    @features = features
  end

  def render(template)
    ERB.new(template).result(binding)
  end
end

build_settings_features_list = Managers::FileManager.load_from_file_YAML(build_settings_file_path)["features"]

if build_settings_features_list.nil? or build_settings_features_list.empty?
	raise "There are no features in " + build_settings_file_path
end

# Generate enum Feature Toggles
utils = FeatureUtils.new(build_settings_features_list)
rendered_enum = utils.render(features_enum_template).strip

Managers::FileManager.save_data_to_file(generated_features_enum_file_path, rendered_enum)
