require 'fileutils'
require 'date'

require_relative 'git_caretaker.rb'

class SwiftFileManager
    def initialize(excluded_files, source_date)
        if not source_date.nilOrEmpty?
            @source_date = Date.parse(source_date)
        end
        @excluded_files = excluded_files
        @new_files = []
        @old_files = []
    end
    
    def old_files
        @old_files
    end
    
    def new_files
        @new_files
    end
    
    def find_list_file_paths(start_folder)
        swift_files = File.join('**', '*.swift')
        Dir.glob(swift_files, base: start_folder) { |file_path|
            if not is_excluded_file(file_path)
                compare_timestamp(file_path)
            end
        }
    end
    
    def find_list_file_paths_from(files_path)
        files_path.each { |file_path|
            if not is_excluded_file(file_path)
                compare_timestamp(file_path)
            end
        }
    end
  
    def is_excluded_file(file_path)
        @excluded_files.each do |exclude_file_path|
            if file_path.include? exclude_file_path
                return true
            end
        end
        return false
    end
    
    private
    
    def compare_timestamp(file_path)
        wrapped_whitespace_file_path = file_path.with_wrapped_whitespace
        creation_date_string = GitСaretaker.get_creation_date(wrapped_whitespace_file_path)
        if creation_date_string.nilOrEmpty?
            @old_files.push(file_path)
            puts ('Creation date of ' + file_path + ' was not found')
        else
            creation_date = Date.parse(creation_date_string)
            puts ('Creation date of ' + file_path + ' is ' + creation_date.to_s)
            if @source_date < creation_date
                @new_files.push(file_path)
            else
                @old_files.push(file_path)
            end
        end
    end
end