require_relative '../../../../managers/managers'
require_relative '../../../../templates/templates'

module Touchlane
  class Features

    def self.generate_enabled_features_extension(builder_features_list, build_settings_features_list)

      # Check is entered features contains in configuration file
      features_diff = builder_features_list - build_settings_features_list

      unless features_diff.empty?
        raise "Unexpected features: " + features_diff.join(', ')
      end

      # Generate enabled features extension from feature names
      enabled_features_extension_template = Templates::FeatureTemplates.enabled_features_extension
      utils = Managers::TemplateManager.new(builder_features_list)

      utils.render(enabled_features_extension_template).strip
    end

    private_class_method :new

  end
end
