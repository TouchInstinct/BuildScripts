require 'fileutils'

require_relative 'array_extension.rb'
require_relative 'git_caretaker.rb'
require_relative 'string_extension.rb'
require_relative 'swift_file_manager.rb'
require_relative 'yaml_manager.rb'

class StrategyMaker
    def initialize(project_root_path, swiftlint_executable_path, touchin_swiftlint_yaml_path)
        @project_root_path = project_root_path        
        @touchin_swiftlint_yaml_path = project_root_path + touchin_swiftlint_yaml_path
        @old_swiftlint_yaml_path = project_root_path + '/.swiftlint.yml'
        
        @temporary_swiftlint_folder_name = project_root_path + '/temporary_swiftlint'
        @touchin_swiftlint_yaml_temporary_path = @temporary_swiftlint_folder_name + '/.touchin_swiftlint.yml'
        @old_swiftlint_yaml_temporary_path = @temporary_swiftlint_folder_name + '/.old_swiftlint.yml'
        
        @swiftlint_autocorrect_command = swiftlint_executable_path + ' autocorrect --path ' + @project_root_path + ' --config '
        @swiftlint_lint_command = swiftlint_executable_path + ' --path ' + @project_root_path + ' --config '
    end
    
    def run_fully_multiple_strategy(source_date)
        create_yaml_managers_and_copy_temporary_files

        exclude_files = unique_exclude_files(@touchin_swiftlint_yaml_manager, @old_swiftlint_yaml_manager)

        swift_files = SwiftFileManager.new(exclude_files, source_date)
        swift_files.find_list_file_paths(@project_root_path)

        total_touchin_excluded_files = exclude_files + swift_files.old_files
        total_old_excluded_files = exclude_files + swift_files.new_files

        @touchin_swiftlint_yaml_manager.update('excluded', total_touchin_excluded_files)
        @old_swiftlint_yaml_manager.update('excluded', total_old_excluded_files)
        
        run_multiple_strategy(@touchin_swiftlint_yaml_temporary_path, @old_swiftlint_yaml_temporary_path)
    end
    
    def run_simplified_multiple_strategy(source_date, source_root_path)
        included_files = GitСaretaker.get_modified_files
        
        if included_files.nilOrEmpty?
            puts 'Git did not found swift files to check'
            return
        end
        
        create_yaml_managers_and_copy_temporary_files

        exclude_files = unique_exclude_files(@touchin_swiftlint_yaml_manager, @old_swiftlint_yaml_manager)
        included_files = included_files.map { |file_path| source_root_path + file_path }
        
        swift_file_manager = SwiftFileManager.new(exclude_files, source_date)
        swift_file_manager.find_list_file_paths_from(included_files)
        
        total_touchin_included_files = swift_file_manager.new_files
        total_old_included_files = swift_file_manager.old_files
        
        @touchin_swiftlint_yaml_manager.update('excluded', [])
        @old_swiftlint_yaml_manager.update('excluded', [])
        
        @touchin_swiftlint_yaml_manager.update('included', total_touchin_included_files)
        @old_swiftlint_yaml_manager.update('included', total_old_included_files)
        
        is_exist_total_touchin_included_files = (not total_touchin_included_files.nilOrEmpty?)
        is_exist_total_old_included_files = (not total_old_included_files.nilOrEmpty?)
        
        if is_exist_total_touchin_included_files and is_exist_total_old_included_files
            run_multiple_strategy(@touchin_swiftlint_yaml_temporary_path, @old_swiftlint_yaml_temporary_path)
        elsif is_exist_total_touchin_included_files and not is_exist_total_old_included_files
            run_single_strategy(@touchin_swiftlint_yaml_temporary_path)
        elsif not is_exist_total_touchin_included_files and is_exist_total_old_included_files
            run_single_strategy(@old_swiftlint_yaml_temporary_path)
        else
            puts 'Git did not found swift files to check'
        end
    end
    
    def run_fully_single_strategy
        run_single_strategy(@touchin_swiftlint_yaml_path)
    end
    
    def run_simplified_single_strategy(source_root_path)
        included_files = GitСaretaker.get_modified_files

        if included_files.nilOrEmpty?
            puts 'Git did not found swift files to check'
            return
        end
        
        create_copy_temporary_touchin_files
        
        touchin_swiftlint_yaml_manager = YamlManager.new(@touchin_swiftlint_yaml_temporary_path)
        touchin_excluded_files = touchin_swiftlint_yaml_manager.get_configuration('excluded')
        swift_files = SwiftFileManager.new(touchin_excluded_files, '')

        included_files = included_files.select { |file_name| not swift_files.is_excluded_file(file_name) }
        included_files = included_files.map { |file_path| source_root_path + file_path }
        
        touchin_swiftlint_yaml_manager.update('excluded', [])
        touchin_swiftlint_yaml_manager.update('included', included_files)
        
        if not included_files.nilOrEmpty?
            run_single_strategy(@touchin_swiftlint_yaml_temporary_path)
        else
            puts 'Git found the swift files to check, but they are excluded in yaml'
        end
    end
    
    private
    
    def run_single_strategy(swiftlint_yaml_path)
        result_swiftlint_command = get_swiftlint_command(swiftlint_yaml_path)
        puts result_swiftlint_command
        run_bash_command(result_swiftlint_command)
    end
    
    def run_multiple_strategy(touchin_swiftlint_yaml_temporary_path, old_swiftlint_yaml_temporary_path)
        touchin_swiftlint_command = get_swiftlint_command(touchin_swiftlint_yaml_temporary_path)
        old_swiftlint_command = get_swiftlint_command(old_swiftlint_yaml_temporary_path)
        result_swiftlint_command = touchin_swiftlint_command + ' && ' + old_swiftlint_command
        puts result_swiftlint_command
        run_bash_command(result_swiftlint_command)
    end
    
    def get_swiftlint_command(swiftlint_yaml_path)
        autocorrect_command = @swiftlint_autocorrect_command + swiftlint_yaml_path
        lint_command = @swiftlint_lint_command + swiftlint_yaml_path
        return autocorrect_command + ' && ' + lint_command
    end
    
    def run_bash_command(bash_command)
        exit (exec bash_command)
    end

    def create_yaml_managers_and_copy_temporary_files
        create_copy_temporary_files
        
        @touchin_swiftlint_yaml_manager = YamlManager.new(@touchin_swiftlint_yaml_temporary_path)
        @old_swiftlint_yaml_manager = YamlManager.new(@old_swiftlint_yaml_temporary_path)
    end
    
    def create_copy_temporary_files
        create_copy_temporary_touchin_files
        FileUtils.cp @old_swiftlint_yaml_path, @old_swiftlint_yaml_temporary_path
    end
    
    def create_copy_temporary_touchin_files
        Dir.mkdir(@temporary_swiftlint_folder_name) unless Dir.exist?(@temporary_swiftlint_folder_name)
        FileUtils.cp @touchin_swiftlint_yaml_path, @touchin_swiftlint_yaml_temporary_path
    end
    
    def unique_exclude_files(touchin_swiftlint_yaml_manager, old_swiftlint_yaml_manager)
        touchin_excluded_files = touchin_swiftlint_yaml_manager.get_configuration('excluded')
        old_excluded_files = old_swiftlint_yaml_manager.get_configuration('excluded')
        common_exclude_files = touchin_excluded_files + old_excluded_files
        unique_exclude_files = common_exclude_files.uniq
        return unique_exclude_files
    end
end