require 'json'

require_relative 'managers/managers'

module Touchlane
  class Features

    def self.generate_features_file_in_project(builder_features_list, build_settings_file_path, project_features_file_path)
      build_settings_features_list = Managers::FileManager.load_from_file_YAML(build_settings_file_path)["features"]

      # Check is entered features contains in configuration file
      features_diff = builder_features_list - build_settings_features_list

      if !features_diff.empty?
        raise "Unexpected features: " + features_diff.join(', ')
      end

      # Generate JSON from feature names
      feature_bodies = builder_features_list.map { |feature_name| { :name => feature_name, :enabled => true} }
      features_full_body = { :features => feature_bodies }
      features_json = JSON.pretty_generate(features_full_body)

      Managers::FileManager.save_data_to_file(project_features_file_path, features_json)
    end

    private_class_method :new

  end
end
