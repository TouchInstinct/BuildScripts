require 'json'
require 'yaml'

module Touchlane
  class Features

    def self.generate_features_file_in_project(builder_features_list, common_features_file_path, project_features_file_path)
      common_features_list = get_features_from_file(common_features_file_path)["features"]

      # Check is entered features contains in configuration file
      features_diff = builder_features_list - common_features_list

      if !features_diff.empty?
        raise "Unexpected features: " + features_diff.join(', ')
      end

      # Generate JSON from feature names
      feature_bodies = builder_features_list.map { |feature_name| { :name => feature_name, :enabled => true} }
      features = { :features => features_body }
      features_json = JSON.pretty_generate(features)

      unless File.exists? project_features_file_path
        raise "Unable to load features from file at #{path}"
      else
        File.open(project_features_file_path, "w") do |f| 
          f.write(features_json)
        end
      end
    end

     def self.get_features_from_file(path)
      unless File.exists? path
        raise "Unable to load features from file at #{path}"
      else
        YAML.load_file(path)["features"]
      end
    end

    private_class_method :new, :get_features_from_file

  end
end
