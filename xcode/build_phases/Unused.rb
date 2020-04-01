# source: https://github.com/PaulTaykalo/swift-scripts/blob/master/unused.rb
#!/usr/bin/ruby
#encoding: utf-8
require 'yaml'
require 'optparse'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

class Item
    def initialize(file, line, at)
        @file = file
        @line = line
        @at = at + 1
        if match = line.match(/(func|let|var|class|enum|struct|protocol)\s+(\w+)/)
            @type = match.captures[0]
            @name = match.captures[1]
        end
    end

    def modifiers
        return @modifiers if @modifiers
        @modifiers = []
        if match = @line.match(/(.*?)#{@type}/)
            @modifiers = match.captures[0].split(" ")
        end
        return @modifiers
    end

    def name
        @name
    end

    def file
        @file
    end

    def to_s
        serialize
    end
    def to_str
        serialize
    end

    def full_file_path
        Dir.pwd + '/' + @file
    end

    def serialize
        "#{@file} has unused \"#{@type.to_s} #{@name.to_s}\""
    end
    def to_xcode
        "#{full_file_path}:#{@at}:0: warning: #{@type.to_s} #{@name.to_s} is unused"
    end


end
class Unused
    def find
        items = []
        unused_warnings = []

        regexps = parse_arguments

        all_files = Dir.glob("**/*.swift").reject do |path|
            File.directory?(path)
        end

        all_files.each { |my_text_file|
            file_items = grab_items(my_text_file)
            file_items = filter_items(file_items)

            non_private_items, private_items = file_items.partition { |f| !f.modifiers.include?("private") && !f.modifiers.include?("fileprivate") }
            items += non_private_items

            # Usage within the file
            if private_items.length > 0
                unused_warnings += find_usages_in_files([my_text_file], [], private_items, regexps)
            end

        }

        xibs = Dir.glob("**/*.xib")
        storyboards = Dir.glob("**/*.storyboard")

        unused_warnings += find_usages_in_files(all_files, xibs + storyboards, items, regexps)

        if unused_warnings.length > 0
            # show warning
            puts "Unused Code Warning!: warning: Total Count #{unused_warnings.length}"
            puts "#{unused_warnings.map { |e| e.to_xcode}.join("\n")}"
            # write log
            Dir.mkdir(directory_name) unless File.exists?("code-quality-reports")
            File.open("code-quality-reports/UnusedLog.txt", "w") do |file|
                file.write("Unused code warnings count: #{unused_warnings.length}\n\n")
                file.write("#{unused_warnings.map { |e| e.serialize }.join("\n")}")
            end
        end
    end

    def parse_arguments
        resources = []

        options = {}
        OptionParser.new do |opts|
            options[:exclude] = []

            opts.on("-c", "--config=FileName") { |c| options[:config] = c }
            opts.on("-i", "--exclude [a, b, c]", Array) { |i| options[:exclude] += i if !i.nil? }

        end.parse!

        # find --config file
        if !options[:config].nil?
            fileName = options[:config]
            resources += YAML.load_file(fileName).fetch("excluded-resources")
            elsif
            puts "---------\n Warning: Config file is not provided \n---------"
        end

        # find --exclude files
        if !options[:exclude].nil?
            resources += options[:exclude]
        end

        # create and return Regexp
        resources.map { |r| Regexp.new(r) }
    end

    def grab_items(file)
        lines = File.readlines(file).map {|line| line.gsub(/^\s*\/\/.*/, "")  }
        items = lines.each_with_index.select { |line, i| line[/(func|let|var|class|enum|struct|protocol)\s+\w+/] }.map { |line, i| Item.new(file, line, i)}
    end

    def filter_items(items)
        items.select { |f|
            !f.name.start_with?("test") && !f.modifiers.include?("@IBAction") && !f.modifiers.include?("override") && !f.modifiers.include?("@objc") && !f.modifiers.include?("@IBInspectable")
        }
    end

    # remove files, that maches excluded Regexps array
    def ignore_files_with_regexps(files, regexps)
        files.select { |f| regexps.all? { |r| r.match(f.file).nil? } }
    end

    def find_usages_in_files(files, xibs, items_in, regexps)
        items = items_in
        usages = items.map { |f| 0 }
        files.each { |file|
            lines = File.readlines(file).map {|line| line.gsub(/^[^\/]*\/\/.*/, "")  }
            words = lines.join("\n").split(/\W+/)
            words_arrray = words.group_by { |w| w }.map { |w, ws| [w, ws.length] }.flatten

            wf = Hash[*words_arrray]

            items.each_with_index { |f, i|
                usages[i] += (wf[f.name] || 0)
            }
            # Remove all items which has usage 2+
            indexes = usages.each_with_index.select { |u, i| u >= 2 }.map { |f, i| i }

            # reduce usage array if we found some functions already
            indexes.reverse.each { |i| usages.delete_at(i) && items.delete_at(i) }
        }

        xibs.each { |xib|
            lines = File.readlines(xib).map {|line| line.gsub(/^\s*\/\/.*/, "")  }
            full_xml = lines.join(" ")
            classes = full_xml.scan(/(class|customClass)="([^"]+)"/).map { |cd| cd[1] }
            classes_array = classes.group_by { |w| w }.map { |w, ws| [w, ws.length] }.flatten

            wf = Hash[*classes_array]

            items.each_with_index { |f, i|
                usages[i] += (wf[f.name] || 0)
            }
            # Remove all items which has usage 2+
            indexes = usages.each_with_index.select { |u, i| u >= 2 }.map { |f, i| i }

            # reduce usage array if we found some functions already
            indexes.reverse.each { |i| usages.delete_at(i) && items.delete_at(i) }

        }

        items = ignore_files_with_regexps(items, regexps)
    end
end


Unused.new.find
