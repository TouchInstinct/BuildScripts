require 'yaml'

module Managers
  class FileManager

    def self.save_data_to_file(path, data)
      unless File.exists? path
        raise "Unable to save data to file at #{path}"
      else
        File.open(path, "w") do |f|
          f.write(data)
        end
      end
    end

    def self.load_from_file_YAML(path)
      unless File.exists? path
        raise "Unable to load data from file at #{path}"
      else
        YAML.load_file(path)
      end
    end

    private_class_method :new

  end
end
