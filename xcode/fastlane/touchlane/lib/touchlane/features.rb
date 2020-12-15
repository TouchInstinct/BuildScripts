module Touchlane
  class Features

    def self.generate_features_hash(builder_features_list, build_settings_features_list)

      # Check is entered features contains in configuration file
      features_diff = builder_features_list - build_settings_features_list

      if !features_diff.empty?
        raise "Unexpected features: " + features_diff.join(', ')
      end

      # Generate hash from feature names
      feature_bodies = builder_features_list.map { |feature_name| { :name => feature_name, :enabled => true } }
      features_full_body = { :features => feature_bodies }
      features_full_body.to_hash()
    end

    private_class_method :new

  end
end
