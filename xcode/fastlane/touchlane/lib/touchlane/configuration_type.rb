module Touchlane
  class ConfigurationType
    DEVELOPMENT = "development"
    ENTERPRISE = "enterprise"
    APP_STORE = "appstore"

    DEVELOPMENT_PREFIX = "Standard"
    ENTERPRISE_PREFIX = "Enterprise"
    APP_STORE_PREFIX = "AppStore"

    private_constant :DEVELOPMENT, :ENTERPRISE, :APP_STORE
    private_constant :DEVELOPMENT_PREFIX, :ENTERPRISE_PREFIX, :APP_STORE_PREFIX

    def initialize(type)
      @type = type

      @is_app_store = type == APP_STORE
      @is_development = type == DEVELOPMENT

      case type
      when DEVELOPMENT
          @export_method = type
          @configuration = "Debug"
          @prefix = DEVELOPMENT_PREFIX
      when ENTERPRISE
          @export_method = type
          @configuration = "Release"
          @prefix = ENTERPRISE_PREFIX
      when APP_STORE
          @export_method = "app-store"
          @configuration = "AppStore"
          @prefix = APP_STORE_PREFIX
      else
        raise "Unknown type passed #{type}"
      end
    end

    private_class_method :new

    attr_reader :export_method, :type, :configuration, :is_app_store, :is_development, :prefix

    def self.from_lane_name(lane_name)
      case
      when lane_name.start_with?(ENTERPRISE_PREFIX)
        from_type(ENTERPRISE)
      when lane_name.start_with?(APP_STORE_PREFIX)
        from_type(APP_STORE)
      when lane_name.start_with?(DEVELOPMENT_PREFIX)
        from_type(DEVELOPMENT)
      else
        raise "Unable to map #{lane_name} to #{ConfigurationType.class}."
        + "Available prefixes: #{DEVELOPMENT_PREFIX}, #{ENTERPRISE_PREFIX}, #{APP_STORE_PREFIX}"
      end
    end

    def self.from_type(type)
      new(type)
    end

    def to_options
      {
        :type => @type,
        :export_method => @export_method,
        :configuration => @configuration
      }
    end
  end
end