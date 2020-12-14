require 'yaml'
require 'erb'

# Input files paths
build_settings_file_path = ARGV[0]
generated_features_enum_file_path = ARGV[1]

features_enum_template =
"
//MARK: - Feature toggles

public enum FeatureToggles: String, Codable, RawRepresentable, CaseIterable {
    <% for @item in @items %>
    case <%= @item %>
    <% end %>
}
"

class FeatureUtils
  include ERB::Util

  attr_accessor :items

  def initialize(items)
    @items = items
  end

  def render(template)
    ERB.new(template).result(binding)
  end
end

def save(path, data)
  unless File.exists? path
    raise "Unable to safe features to file at #{path}"
  else
    File.open(path, "w") do |f|
      f.write(data)
    end
  end
end

def get_features_from_file(path)
  unless File.exists? path
    raise "Unable to load features from file at #{path}"
  else
    YAML.load_file(path)
  end
end

build_settings_features_list = get_features_from_file(build_settings_file_path)["features"]
utils = FeatureUtils.new(build_settings_features_list)

data = utils.render(features_enum_template).strip
save(generated_features_enum_file_path, data)
