require 'yaml'
require 'optparse'
require 'ostruct'
require 'date'
require 'fileutils'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

class String
    def with_wrapped_whitespace
        self.gsub(/\s+/, '\ ')
    end
    
    def filter_allowed_symbol_into_path
        self.gsub!(/[^0-9A-Za-z \-+.\/]/, '')
    end
  
    def true?
        self.to_s.downcase == "true"
    end
    
    def add_back_to_path(count)
        string = self
        count.to_i.times { |i|
            string = '../' + string
        }
        return string
    end
    
    def nilOrEmpty?
        self.nil? or self.empty?
    end
end

class Array
    def nilOrEmpty?
        self.nil? or self.empty?
    end
end

class YamlManager
    def initialize(swiftlint_yaml_path)
        @swiftlint_yaml_path = swiftlint_yaml_path
        @configuration ||= YAML.load(File.read(@swiftlint_yaml_path))
    end
    
    def get_configuration(key)
      @configuration[key]
    end

    def update(key, new_configuration_values)
      @configuration[key] = new_configuration_values
      save_settings(@configuration)
    end

    private

    def save_settings(settings)
      File.write(@swiftlint_yaml_path, settings.to_yaml)
    end
end

class SettingOption
    def initialize
        @options = OpenStruct.new
        OptionParser.new do |opt|
            opt.on('-s', '--source_directory STRING', 'The directory of start') { |option| @options.source_directory = option }
            opt.on('-p', '--pods_directory STRING', 'The directory of pods') { |option| @options.pods_directory = option }
            opt.on('-c', '--check_mode MODE', 'The mode of check is "fully" or "simplified"') { |option| @options.check_mode = option }
            opt.on('-u', '--use_multiple BOOL', 'the flag indicates the use of multiple yaml swiftlint configurations') { |option| @options.use_multiple = option }
            opt.on('-d', '--source_date DATE', 'The date of grouping files according new and old swiftlint rules') { |option| @options.source_date = option }
            opt.on('-y', '--touchin_swiftlint_yaml_path STRING', 'The path to the touchin swiftlint yaml relative to the source directory') { |option| @options.touchin_swiftlint_yaml_path = option }
            opt.on('-g', '--depth_git_count Int', 'The depth between the git directory and sources directory') { |option| @options.depth_git_count = option }
        end.parse!
        
        if @options.check_mode.to_s.nilOrEmpty?
            @options.check_mode = 'fully'
        end

        if @options.use_multiple.to_s.nilOrEmpty?
            @options.use_multiple = 'false'
        end

        if @options.depth_git_count.to_s.nilOrEmpty?
            @options.depth_git_count = 0
        end
        
        if @options.touchin_swiftlint_yaml_path.to_s.nilOrEmpty?
            @options.touchin_swiftlint_yaml_path = '/build-scripts/xcode/.swiftlint.yml'
        end
    end
    
    def source_directory
        @options.source_directory
    end
    
    def source_date
        @options.source_date
    end
    
    def pods_directory
        @options.pods_directory
    end
    
    def check_mode
        @options.check_mode
    end
    
    def use_multiple
        @options.use_multiple
    end
    
    def depth_git_count
        @options.depth_git_count
    end
    
    def touchin_swiftlint_yaml_path
        @options.touchin_swiftlint_yaml_path
    end
end

class CommandUtils
    def self.make_command(command)
        command = command.to_s
        return `#{command}`
    end
end

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
        puts file_path
        if creation_date_string.nilOrEmpty?
            @old_files.push(file_path)
            puts 'Not found the creation date'
        else
            creation_date = Date.parse(creation_date_string)
            puts creation_date
            if @source_date < creation_date
                @new_files.push(file_path)
            else
                @old_files.push(file_path)
            end
        end
    end
end

class StrategyMaker
    def initialize(source_directory, pods_directory, touchin_swiftlint_yaml_path)
        @source_directory = source_directory
        @pods_directory = pods_directory
        @swiftlint = pods_directory + '/SwiftLint/swiftlint'
        
        @touchin_swiftlint_yaml_path = source_directory + touchin_swiftlint_yaml_path
        @old_swiftlint_yaml_path = source_directory + '/.swiftlint.yml'
        
        @temporary_swiftlint_folder_name = source_directory + '/temporary_swiftlint'
        @touchin_swiftlint_yaml_temporary_path = @temporary_swiftlint_folder_name + '/.touchin_swiftlint.yml'
        @old_swiftlint_yaml_temporary_path = @temporary_swiftlint_folder_name + '/.old_swiftlint.yml'
        
        @swiftlint_autocorrect_command = @swiftlint + ' autocorrect --path ' + @source_directory + ' --config '
        @swiftlint_lint_command = @swiftlint + ' --path ' + @source_directory + ' --config '
    end
    
    def make_fully_multiple_strategy(source_date)
        create_copy_temporary_files

        touchin_swiftlint_yaml_manager = YamlManager.new(@touchin_swiftlint_yaml_temporary_path)
        old_swiftlint_yaml_manager = YamlManager.new(@old_swiftlint_yaml_temporary_path)

        touchin_excluded_files = touchin_swiftlint_yaml_manager.get_configuration('excluded')
        old_excluded_files = old_swiftlint_yaml_manager.get_configuration('excluded')
        common_exclude_files = touchin_excluded_files + old_excluded_files
        unique_exclude_files = common_exclude_files.uniq

        swift_files = SwiftFileManager.new(unique_exclude_files, source_date)
        swift_files.find_list_file_paths(@source_directory)

        total_touchin_excluded_files = unique_exclude_files + swift_files.old_files
        total_old_excluded_files = unique_exclude_files + swift_files.new_files

        touchin_swiftlint_yaml_manager.update('excluded', total_touchin_excluded_files)
        old_swiftlint_yaml_manager.update('excluded', total_old_excluded_files)
        
        make_multiple_strategy(@touchin_swiftlint_yaml_temporary_path, @old_swiftlint_yaml_temporary_path)
    end
    
    def make_simplified_multiple_strategy(source_date, depth_git_count)
        included_files = GitСaretaker.get_modified_files
        
        if included_files.nilOrEmpty?
            puts 'Git did not found swift files to check'
            return
        end
        
        create_copy_temporary_files
        
        touchin_swiftlint_yaml_manager = YamlManager.new(@touchin_swiftlint_yaml_temporary_path)
        old_swiftlint_yaml_manager = YamlManager.new(@old_swiftlint_yaml_temporary_path)

        touchin_excluded_files = touchin_swiftlint_yaml_manager.get_configuration('excluded')
        old_excluded_files = old_swiftlint_yaml_manager.get_configuration('excluded')
        common_exclude_files = touchin_excluded_files + old_excluded_files
        unique_exclude_files = common_exclude_files.uniq
        
        included_files = included_files.map { |file_path| file_path.add_back_to_path(depth_git_count) }
        
        swift_file_manager = SwiftFileManager.new(unique_exclude_files, source_date)
        swift_file_manager.find_list_file_paths_from(included_files)
        
        total_touchin_included_files = swift_file_manager.new_files
        total_old_included_files = swift_file_manager.old_files
        
        touchin_swiftlint_yaml_manager.update('excluded', [])
        old_swiftlint_yaml_manager.update('excluded', [])
        
        touchin_swiftlint_yaml_manager.update('included', total_touchin_included_files)
        old_swiftlint_yaml_manager.update('included', total_old_included_files)
        
        is_exist_total_touchin_included_files = (not total_touchin_included_files.nilOrEmpty?)
        is_exist_total_old_included_files = (not total_old_included_files.nilOrEmpty?)
        
        if is_exist_total_touchin_included_files and is_exist_total_old_included_files
            make_multiple_strategy(@touchin_swiftlint_yaml_temporary_path, @old_swiftlint_yaml_temporary_path)
        elsif is_exist_total_touchin_included_files and not is_exist_total_old_included_files
            make_single_strategy(@touchin_swiftlint_yaml_temporary_path)
        elsif not is_exist_total_touchin_included_files and is_exist_total_old_included_files
            make_single_strategy(@old_swiftlint_yaml_temporary_path)
        else
            puts 'Git did not found swift files to check'
        end
    end
    
    def make_fully_single_strategy
        make_single_strategy(@touchin_swiftlint_yaml_path)
    end
    
    def make_simplified_single_strategy(depth_git_count)
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
        included_files = included_files.map { |file_path| file_path.add_back_to_path(depth_git_count) }
        
        touchin_swiftlint_yaml_manager.update('excluded', [])
        touchin_swiftlint_yaml_manager.update('included', included_files)
        
        if not included_files.nilOrEmpty?
            make_single_strategy(@touchin_swiftlint_yaml_temporary_path)
        else
            puts 'Git found the swift files to check, but they are excluded in yaml'
        end
    end
    
    private
    
    def make_single_strategy(swiftlint_yaml_path)
        result_swiftlint_command = get_swiftlint_command(swiftlint_yaml_path)
        puts result_swiftlint_command
        make_bash_command(result_swiftlint_command)
    end
    
    def make_multiple_strategy(touchin_swiftlint_yaml_temporary_path, old_swiftlint_yaml_temporary_path)
        touchin_swiftlint_command = get_swiftlint_command(touchin_swiftlint_yaml_temporary_path)
        old_swiftlint_command = get_swiftlint_command(old_swiftlint_yaml_temporary_path)
        result_swiftlint_command = touchin_swiftlint_command + ' && ' + old_swiftlint_command
        puts result_swiftlint_command
        make_bash_command(result_swiftlint_command)
    end
    
    def get_swiftlint_command(swiftlint_yaml_path)
        autocorrect_command = @swiftlint_autocorrect_command + swiftlint_yaml_path
        lint_command = @swiftlint_lint_command + swiftlint_yaml_path
        return autocorrect_command + ' && ' + lint_command
    end
    
    def make_bash_command(bash_command)
        exit (exec bash_command)
    end
    
    def create_copy_temporary_files
        create_copy_temporary_touchin_files
        FileUtils.cp @old_swiftlint_yaml_path, @old_swiftlint_yaml_temporary_path
    end
    
    def create_copy_temporary_touchin_files
        Dir.mkdir(@temporary_swiftlint_folder_name) unless Dir.exist?(@temporary_swiftlint_folder_name)
        FileUtils.cp @touchin_swiftlint_yaml_path, @touchin_swiftlint_yaml_temporary_path
    end
end

setting = SettingOption.new
maker = StrategyMaker.new(setting.source_directory, setting.pods_directory, setting.touchin_swiftlint_yaml_path)

if setting.check_mode.eql? 'fully' and setting.use_multiple.true?
    maker.make_fully_multiple_strategy(setting.source_date)
elsif setting.check_mode.eql? 'fully' and not setting.use_multiple.true?
    maker.make_fully_single_strategy
elsif setting.check_mode.eql? 'simplified' and setting.use_multiple.true?
    maker.make_simplified_multiple_strategy(setting.source_date, setting.depth_git_count)
elsif setting.check_mode.eql? 'simplified' and not setting.use_multiple.true?
    maker.make_simplified_single_strategy(setting.depth_git_count)
end
