require_relative 'array_extension.rb'
require_relative 'command_utils.rb'
require_relative 'string_extension.rb'

class GitСaretaker < CommandUtils
    def self.get_modified_files
        non_indexed_files = get_files_from('git diff --name-only | sed s/.*/"&,"/ ')
        indexed_files = get_files_from('git diff --cached --name-only | sed s/.*/"&,"/ ')
        
        modified_files = non_indexed_files + indexed_files
        unique_modified_files = modified_files.uniq
        
        unique_modified_swift_files = []
        if not unique_modified_files.nilOrEmpty?
            unique_modified_swift_files = unique_modified_files.select { |file_path|
                file_path.to_s.filter_allowed_symbol_into_path
                file_path.to_s.include? '.swift'
            }
        end
        
        return unique_modified_swift_files
    end
    
    def self.get_creation_date(file_path)
        git_command = 'git log --follow --format=%cD --reverse -- ' + file_path + ' | head -1'
        return make_command(git_command)
    end
    
    private
    
    def self.get_files_from(command)
        files_as_string = make_command(command)
        return files_as_string.split(',')
    end
end