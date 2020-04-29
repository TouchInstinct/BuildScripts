require "yaml"

module Touchlane
  class Configuration
    def initialize(type, app_identifier, apple_id, team_id, itc_team_id)
      @type = type
      @app_identifier = app_identifier
      @apple_id = apple_id
      @team_id = team_id
      @itc_team_id = itc_team_id
    end

    attr_reader :type, :app_identifier, :apple_id, :team_id, :itc_team_id

    def self.from_file(path, type)
      hash_of_types = load_hash_of_types_from_file(path)
      attrs_hash = hash_of_types[type]

      unless attrs_hash
        raise "There is no configuration with type #{type}. Available types: #{attrs_hash.keys}"
      else
        config_type = Touchlane::ConfigurationType.from_type(type)
        new(config_type, attrs_hash["app_identifier"], attrs_hash["apple_id"], attrs_hash["team_id"], attrs_hash["itc_team_id"])
      end
    end

    def self.load_hash_of_types_from_file(path)
      unless File.exists? path
        raise "Unable to load configurations from file at #{path}"
      else
        YAML.load_file(path)
      end
    end

    private_class_method :new, :load_hash_of_types_from_file

    def to_options
      {
        :app_identifier => @app_identifier,
        :apple_id => @apple_id,
        :username => @apple_id,
        :team_id => @team_id,
        :itc_team_id => @itc_team_id,
      }
      .merge(type.to_options)
    end
  end
end
